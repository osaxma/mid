import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:mid_protocol/mid_protocol.dart';

import 'handlers.dart';

class WebsocketHandler {
  final List<StreamBaseHandler> handlers;

  final List<MessageInterceptor> interceptors;
  WebsocketHandler({
    required this.handlers,
    required this.interceptors,
  });

  // a workaround to pass the request to the messageHandler
  FutureOr<Response> wsHandler(Request request) async {
    return webSocketHandler((WebSocketChannel webSocket) {
      _messagesHandler(webSocket, request);
    })(request);
  }

  // The webSocket here is for a single client
  void _messagesHandler(WebSocketChannel webSocket, Request request) {
    final handler = _MessageHandler(
      webSocket.stream, // this is a single sub stream! TODO: do same logic as in client
      webSocket.sink,
      _getHandler,
      request,
      interceptors: interceptors,
    );
    handler.listen();
  }

  StreamBaseHandler _getHandler(String route) {
    for (final handler in handlers) {
      if (handler.route == route) {
        return handler;
      }
    }

    throw Exception('Stream handler for $route not found');
  }
}

// TODO: this class is a mess -- it's handling the connection as well as message requests.
//       at least move all message requests out
class _MessageHandler {
  // note: the request may contains authentication token which may expire during the life of this connection
  //       the client may request to update these headers solely to update the auth token.
  //       The goal here is to provide the user of the library a way to intercept messages and therefore
  //       decides whether the headers should be updated, or if the connection should terminate.
  //       The interceptors should provide the request headers with each message.
  final Request request;
  final Stream stream;
  final WebSocketSink sink;
  late final StreamSubscription connSub;
  StreamSubscription? _handlerSub;
  final StreamBaseHandler Function(String) streamHandlerProvider;
  final List<MessageInterceptor> interceptors;

  final List<_EndPointSubscription> activeSubs = [];

  bool initted = false;

  _MessageHandler(
    this.stream,
    this.sink,
    this.streamHandlerProvider,
    this.request, {
    this.interceptors = const [],
  });

  void listen() {
    connSub = stream.listen(onData);
    connSub.onError(_onConnError);
    connSub.onDone(_onConnDone);
  }

  void _onConnError(dynamic err) {
    // TODO: this might not work if the conn failed
    sendMessage(Message(type: MessageType.error, payload: err));
    _connDispose();
  }

  void _onConnDone() => _connDispose();

  void _connDispose() async {
    // this is causing an issue where the program does not exit :/
    // see: https://github.com/dart-lang/sdk/issues/49777
    // connSub.cancel();
    await sink.close(1000, 'done');
  }

  void onData(dynamic event) {
    try {
      final message = interceptClient(Message.fromJson(event));
      switch (message.type) {
        case MessageType.ping:
          sendMessage(pongMsg.copyWith(id: message.id));
          break;
        case MessageType.connectionInit:
          sendMessage(ackMsg.copyWith(id: message.id));
          break;
        case MessageType.updateHeaders:
          // TODO: Handle this case.
          break;

        case MessageType.pong:
          // TODO: Handle this case.
          break;

        case MessageType.subscribe:
          handleSubscribe(message);
          // TODO: Handle this case.
          break;
        case MessageType.stop:
          handleStop(message);
          break;
        case MessageType.endpoint:
          // TODO: Handle this case.
          break;

        // These are Server --> Client types so they are not supposed to be sent by the client
        case MessageType.error:
        case MessageType.data:
        case MessageType.connectionAcknowledge:
          sendMessage(Message(type: MessageType.error, payload: 'Invalid MessageType ${message.type}'));
      }
    } catch (e) {
      final errorMessage = Message(
        type: MessageType.error,
        payload: 'message: $event\nerror: $e',
      );
      sendMessage(errorMessage);
      connSub.cancel();
      // TODO: provide a meaningful close code and close reason
      sink.close(1000, 'TBD');
      _handlerSub?.cancel();
    }
  }

  void handleStop(Message message) {
    final id = message.id;
    if (id == null) {
      sendMessage(
        Message(
          id: id,
          type: MessageType.error,
          payload: 'Subscriptions must have a message id',
        ),
      );
      return;
    }

    // verify this happened?
    cancelActiveSub(id);
    // TODO: send acknowledgement?
  }

  void handleSubscribe(Message message) {
    final payload = message.payload;
    final id = message.id;

    if (payload == null || payload is! Map<String, dynamic>) {
      sendMessage(
        Message(
          id: id,
          type: MessageType.error,
          payload: 'the payload for ${message.type.name} must be a string',
        ),
      );
      return;
    }

    if (id == null) {
      sendMessage(
        Message(
          id: id,
          type: MessageType.error,
          payload: 'Subscriptions must have a message id',
        ),
      );
      return;
    }

    // TODO: make sure to check for duplicate ids at the client side
    // the client should check for duplicate ids before sending them
    // otherwise, returning a message with the same id would be received by the former subscription
    //
    // if (activeSubs.any((e) => e.id == message.id)) {
    //   sendMessage(
    //     Message(
    //       id: message.id,
    //       type: MessageType.error,
    //       payload: 'An active subscription already exists with message id ${message.id}. Message must have a message id',
    //     ),
    //   );
    // }

    final route = payload['route'];
    final data = payload['data'];

    final handler = streamHandlerProvider(route);

    final stream = handler.handler(data);

    final sub = _handlerSub = stream.listen(
      (event) {
        sink.add(
          Message(
            id: id,
            type: MessageType.data,
            payload: event,
          ).toJson(),
        );
      },
      onDone: () {
        cancelActiveSub(id);
      },
      onError: (err, s) {
        cancelActiveSub(id);
        sendMessage(
          Message(id: id, type: MessageType.error, payload: 'Endpoint subscription error. $err'),
        );
      },
    );

    activeSubs.add(_EndPointSubscription(message.id!, sub));
  }

  void cancelActiveSub(String id) {
    final idx = activeSubs.indexWhere((element) => element.messageID == id);
    if (idx != -1) {
      activeSubs[idx].sub.cancel();
      activeSubs.removeAt(idx);
    }
    if (activeSubs.isEmpty) {
      _connDispose();
    }
  }

  void sendMessage(Message message) {
    sink.add(interceptServer(message).toJson());
  }

  Message interceptClient(Message message) {
    return interceptors.fold(message, (previousValue, element) => element.clientMessage(previousValue));
  }

  Message interceptServer(Message message) {
    return interceptors.fold(message, (previousValue, element) => element.serverMessage(previousValue));
  }
}

const pongMsg = Message(type: MessageType.pong);
const ackMsg = Message(type: MessageType.connectionAcknowledge);

/// simple wrapper around a subscription
///
/// this is used to keep a reference of a subscription for canceling it or any other reason.
class _EndPointSubscription {
  final String messageID;
  final StreamSubscription<String> sub;

  _EndPointSubscription(this.messageID, this.sub);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _EndPointSubscription && other.messageID == messageID;
  }

  @override
  int get hashCode => messageID.hashCode;
}
