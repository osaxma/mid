import 'dart:async';
import 'dart:convert';

import 'package:mid/protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MidWebSocketClient {
  final Uri uri;
  MidWebSocketClient({
    required this.uri,
  });
  // TODO: this should be initted in a method for handling errors and retrying
  WebSocketChannel? _conn;

  void connect() {
    _conn = WebSocketChannel.connect(uri);
  }

  void close() {
    _conn?.sink.close(1000, 'Normal Closure');
    _conn = null;
  }

  // TODO: should this be <Message> instead and handle [MessageType.error] here?
  Stream<dynamic> get stream {
    if (_conn == null) {
      throw Exception('Websocket connection was not initialized');
    }
    return _conn!.stream;
  }

  Sink<dynamic> get sink {
    if (_conn == null) {
      throw Exception('Websocket connection was not initialized');
    }
    return _conn!.sink;
  }

  Stream<dynamic> executeStream(Map<String, dynamic> args, String route) {
    if (_conn == null) {
      connect();
    }
    final id = 'random_string';
    final initMsg = Message(
      id: 'random_string',
      type: MessageType.connectionInit,
      payload: {
        'route': route,
        'data': args,
      },
    ).toJson();

    final stopMsg = Message(
      id: id,
      type: MessageType.stop,
    ).toJson();

    final ctrl = StreamController();
    StreamSubscription? sub;

    void dispose() {
      sub?.cancel();
      ctrl.close();
      sink.add(stopMsg);
    }

    ctrl.onListen = () {
      sub = stream
          .map((event) => Message.fromJson(event))
          .where((event) => event.id == id)
          .where((event) {
            if (event.type == MessageType.error) {
              ctrl.addError(event);
              return false;
            }
            return true;
          })
          // TODO: make sure the payload is a string first
          //       all streams data are encoded as json string in the server handlers.
          .map((event) => event.payload as String)
          .listen((event) {
            ctrl.sink.add(json.decode(event));
          }, onDone: () {
            dispose();
          }, onError: (err) {
            ctrl.addError(err);
            dispose();
          });
      sink.add(initMsg);
    };

    ctrl.onCancel = () {
      dispose();
    };

    return ctrl.stream;
  }
}
