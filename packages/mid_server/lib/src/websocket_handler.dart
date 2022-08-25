import 'dart:async';

import 'package:mid_server/src/interceptor.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:mid_protocol/mid_protocol.dart';

import 'handlers.dart';

class WebsocketHandler {
  final List<StreamBaseHandler> handlers;

  final List<MessageInterceptorServer> interceptors;
  WebsocketHandler({
    required this.handlers,
    required this.interceptors,
  });

  // a workaround to access the request
  // this was needed previously to access the request headers
  // but since [MessageType.connectionInit] and [MessageType.connectionUpdate]
  // contains the headers now, this may not be needed anymore.
  FutureOr<Response> wsHandler(Request request) async {
    return webSocketHandler(_messagesHandler)(request);
  }

  void _messagesHandler(WebSocketChannel webSocket) {
    final handler = _ConnectionHandler(
      webSocket.stream,
      webSocket.sink,
      _getHandler,
      interceptors: interceptors,
    );
    handler.listen();
  }

  StreamBaseHandler? _getHandler(String route) {
    for (final handler in handlers) {
      if (handler.route == route) {
        return handler;
      }
    }

    // throw Exception('Stream handler for $route not found');
    return null;
  }
}

// TODO: this class is a mess -- it's handling the connection as well as message requests.
//       at least move all message requests out
class _ConnectionHandler {
  final Stream stream;
  final WebSocketSink sink;
  late final StreamSubscription connSub;
  final StreamBaseHandler? Function(String) streamHandlerProvider;
  final List<MessageInterceptorServer> interceptors;

  final List<_EndPointSubscription> activeSubs = [];

  Map<String, String> _headers = {};

  bool initted = false;

  _ConnectionHandler(
    this.stream,
    this.sink,
    this.streamHandlerProvider, {
    this.interceptors = const [],
  });

  void listen() {
    connSub = stream.listen(onData);
    connSub.onError(_onConnError);
    connSub.onDone(_onConnDone);
  }

  void _onConnError(dynamic err) {
    _connDispose();
  }

  void _onConnDone() => _connDispose();

  // TODO: remove the default values so the caller must provide appropriate closeCode and closeReason.
  void _connDispose([int closeCode = 1000, closeReason = 'normal closure']) async {
    // TODO: re-evaluate if this is necessary since it may be causing a memory leak when called:
    //       see: https://github.com/dart-lang/sdk/issues/49777
    // connSub.cancel();

    // cancel any active subs
    for (var activeSub in activeSubs) {
      await activeSub.cancel();
    }
    await sink.close(closeCode, closeReason);
  }

  void onData(dynamic event) {
    try {
      Message message = Message.fromJson(event);

      // we need to extract the headers so they are available for the interceptors
      if (message is ConnectionInitMessage || message is ConnectionUpdateMessage) {
        _headers = (message.payload as ConnectionPayload).headers;
      }

      // intercept message
      message = interceptClient(Message.fromJson(event));
      // in case the interceptor returns an error message
      if (message is ErrorMessage) {
        throw message;
      }
      switch (message.type) {
        case MessageType.ping:
          sendMessage(pongMsg);
          break;
        case MessageType.connectionInit:
          // if the interceptClient didn't reject the message, then it's acknowledged
          sendMessage(ConnectionAcknowledgeMessage());
          break;
        case MessageType.connectionUpdate:
          // if the interceptClient didn't reject the message, then it's acknowledged
          sendMessage(ConnectionAcknowledgeMessage());
          break;
        case MessageType.pong:
          handlePong(message);
          break;
        case MessageType.subscribe:
          handleSubscribe(message);
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
        case MessageType.complete:
        case MessageType.connectionAcknowledge:
          sendMessage(
            ErrorMessage(
              id: message.id,
              payload: ErrorPayload(
                errorCode: -1, // TODO
                errorMessage: 'Invalid MessageType ${message.type}',
              ),
            ),
          );
      }
    } catch (e) {
      late final Message errorMessage;
      if (e is Message) {
        errorMessage = e;
      } else {
        errorMessage = ErrorMessage(
          id: defaultErrorID,
          payload: ErrorPayload(
            errorCode: -1, // TODO
            errorMessage: 'message: $event\nerror: $e',
          ),
        );
      }

      sendMessage(errorMessage);

      // TODO: decide when we neet to terminate the connection
      // TODO: provide a meaningful close code and close reason
      _connDispose();
    }
  }

  void handlePong(Message message) {
    // TODO: notifiy the ping sender
  }

  void handleEndpoint(Message message) {
    if (message is! EndpointMessage) {
      throw ErrorMessage(
        id: defaultErrorID,
        payload: ErrorPayload(
          errorCode: -1, // TODO
          errorMessage: 'MessageType.endpoint must have an EndpointMessage type',
        ),
      );
    }
  }

  void handleStop(Message message) {
    final id = message.id;

    sendMessage(CompleteMessage(id: id));

    // verify this happened?
    cancelActiveSub(id);
    // TODO: send acknowledgement?
  }

  void handleSubscribe(Message message) {
    final payload = message.payload;
    final id = message.id;

    if (payload == null || payload is! SubscribePayload) {
      sendMessage(
        ErrorMessage(
          id: id,
          payload: ErrorPayload(
            errorCode: -1, // TODO
            errorMessage:
                'the payload for ${message.type.name} must be a SubscribePayload but recived ${payload.runtimeType}',
          ),
        ),
      );
      return;
    }

    if (activeSubs.any((e) => e.messageID == id)) {
      sendMessage(ErrorMessage(
        id: id,
        payload: ErrorPayload(
          errorCode: -1, // TODO
          errorMessage: 'An active subscription already exists with message id $id. Message must have a message id',
        ),
      ));
      return;
    }

    final route = payload.route;
    final data = payload.args;

    final handler = streamHandlerProvider(route);

    if (handler == null) {
      sendMessage(ErrorMessage(
        id: id,
        payload: ErrorPayload(
          errorCode: -1, // TODO
          errorMessage: 'No handlers were found for the given route: $route',
        ),
      ));
      return;
    }

    late final Stream<String> stream;
    try {
      stream = handler.handler(data);
    } catch (e) {
      sendMessage(ErrorMessage(
        id: id,
        payload: ErrorPayload(
          errorCode: -1, // TODO
          errorMessage: 'The handler for "$route" route failed to return.\nerror:\n$e',
        ),
      ));
      return;
    }

    final sub = stream.listen(
      (event) {
        sink.add(
          DataMessage(
            id: id,
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
          ErrorMessage(
            id: id,
            payload: ErrorPayload(
              errorCode: -1, // TODO
              errorMessage: 'Endpoint subscription error. $err',
            ),
          ),
        );
      },
    );

    activeSubs.add(_EndPointSubscription(message.id, sub));
  }

  Future<void> cancelActiveSub(String id) async {
    final idx = activeSubs.indexWhere((element) => element.messageID == id);
    if (idx != -1) {
      await activeSubs[idx].cancel();
      activeSubs.removeAt(idx);
    }
    if (activeSubs.isEmpty) {
      _connDispose();
    }
  }

  void sendMessage(Message message) {
    late final Message msg;
    try {
      msg = interceptServer(message);
    } catch (e) {
      if (e is Message) {
        msg = e;
      } else {
        msg = ErrorMessage(
          id: defaultErrorID,
          payload: ErrorPayload(
            errorCode: -1, // TODO,
            errorMessage: e.toString(),
          ),
        );
      }
    }

    sink.add(msg.toJson());

    if (msg is ErrorMessage) {
      // && msg.payload.errorCode > x
      // TODO: decide if the connection should be terminated after sending the message

    }
  }

  Message interceptClient(Message message) {
    return interceptors.fold(message, (previousValue, element) => element.clientMessage(previousValue, _headers));
  }

  Message interceptServer(Message message) {
    return interceptors.fold(message, (previousValue, element) => element.serverMessage(previousValue));
  }
}

const pingMsg = PingMessage();
const pongMsg = PongMessage();
const ackMsg = ConnectionAcknowledgeMessage();

/// simple wrapper around a subscription
///
/// this is used to keep a reference of a subscription for canceling it or any other reason.
class _EndPointSubscription {
  final String messageID;
  final StreamSubscription<String> sub;

  Future<void> cancel() async {
    await sub.cancel();
  }

  _EndPointSubscription(this.messageID, this.sub);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _EndPointSubscription && other.messageID == messageID;
  }

  @override
  int get hashCode => messageID.hashCode;
}
