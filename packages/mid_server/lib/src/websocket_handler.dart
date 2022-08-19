import 'dart:async';

import 'package:mid/protocol.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'handlers.dart';
import 'websocket_interceptor.dart';

class WebsocketHandler {
  final List<StreamBaseHandler> handlers;

  // TODO: add messages middleware

  WebsocketHandler({
    required this.handlers,
  });

  // a workaround to pass the request to the messageHandler
  FutureOr<Response> wsHandler(Request request) async {
    return webSocketHandler((WebSocketChannel webSocket) {
      _messagesHandler(webSocket, request);
    })(request);
  }

  void _messagesHandler(WebSocketChannel webSocket, Request request) {
    final handler = _MessageHandler(
      webSocket.stream,
      webSocket.sink,
      _getHandler,
      request,
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

class _MessageHandler {
  // note: the request may contains authentication token which may expire during the life of this connection
  //       the client may request to update these headers solely to update the auth token.
  //       The goal here is to provide the user of the library a way to intercept messages and therefore
  //       decides whether the headers should be updated, or if the connection should terminate.
  //       The interceptors should provide the request headers with each message.
  final Request request;
  final Stream stream;
  final WebSocketSink sink;
  late final StreamSubscription sub;
  StreamSubscription? _handlerSub;
  final StreamBaseHandler Function(String) streamHandlerProvider;
  final List<MessageInterceptor> interceptors;

  bool initted = false;

  _MessageHandler(
    this.stream,
    this.sink,
    this.streamHandlerProvider,
    this.request, {
    this.interceptors = const [],
  });

  void listen() {
    sub = stream.listen(onData);
    sub.onError(onError);
    sub.onDone(onDone);
  }

  void onData(dynamic event) {
    print('received event $event');
    try {
      var message = Message.fromJson(event);
      message = interceptClient(message);
      switch (message.type) {
        case MessageType.ping:
          sendMessage(pongMsg);
          break;
        case MessageType.connectionInit:
          handleInit(message);
          break;
        case MessageType.updateHeaders:
          // TODO: Handle this case.
          break;

        case MessageType.pong:
          // TODO: Handle this case.
          break;

        case MessageType.stop:
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
      sub.cancel();
      // TODO: provide a meaningful close code and close reason
      sink.close(1000, 'TBD');
      _handlerSub?.cancel();
    }
  }

  void handleInit(Message message) {
    final payload = message.payload;
    if (payload == null || payload is! Map<String, dynamic>) {
      throw Exception('the payload for ${message.type.name} must be a string');
    }

    final route = payload['route'];
    final data = payload['data'];

    final handler = streamHandlerProvider(route);

    final stream = handler.handler(data);

    _handlerSub = stream.listen(
      (event) {
        sink.add(Message(type: MessageType.data, payload: event).toJson());
      },
      onDone: onDone,
      onError: onError,
    );
  }

  void onError(dynamic err) {
    sink.add(Message(type: MessageType.error, payload: err));
    _dispose();
  }

  void onDone() => _dispose();

  void _dispose() {
    sub.cancel();
    sink.close(1000, 'done');
    _handlerSub?.cancel();
  }

  void sendMessage(Message message) {
    message = interceptServer(message);
    sink.add(message.toJson());
  }

  Message interceptClient(Message message) {
    for (final i in interceptors) {
      message = i.clientMessage(message, request);
    }
    return message;
  }

  Message interceptServer(Message message) {
    for (final i in interceptors) {
      message = i.serverMessage(message, request);
    }
    return message;
  }
}

const pongMsg = Message(type: MessageType.pong);
