import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:mid/protocol.dart';

class BaseClient {
  /// The server URL
  final String url;

  /// A function that should provide an up-to-date headers for each request
  ///
  /// e.g. Bearer Authentication (token)
  // TODO: this is a temp solution until we support either interceptors or a custom `ConnectionData`
  //       speaking of which, a custom `ConnectionData` is preferable since it can be used with both
  //       http and websocket as well as hide the `http` stuff under the hood.
  final Map<String, String> Function() headersProvider;

  BaseClient({required this.url, required this.headersProvider});

  Future<dynamic> executeHttp(Map<String, dynamic> args, String route) async {
    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return data;
  }

  Stream<dynamic> executeStream(Map<String, dynamic> args, String route) {
    final ws = WebSocketChannel.connect(Uri.parse('ws://localhost:8000/ws'));

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
      ws.sink.add(stopMsg);
    }

    ctrl.onListen = () {
      sub = ws.stream
          .map((event) => Message.fromJson(event))
          .where((event) => event.id == id)
          .where((event) {
            if (event.type == MessageType.error) {
              ctrl.addError(event);
              return false;
            }
            return true;
          })
          .map((event) => event.payload)
          .listen((event) {
            ctrl.sink.add(event);
          }, onDone: () {
            dispose();
          }, onError: (err) {
            ctrl.addError(err);
            dispose();
          });
      ws.sink.add(initMsg);
    };

    ctrl.onCancel = () {
      dispose();
    };

    return ctrl.stream;
  }
}

class MidWebSocketClient {
  final String url;
  MidWebSocketClient({
    required this.url,
  });
  // TODO: this should be initted in a method for handling errors and retrying
  late final _conn = WebSocketChannel.connect(Uri.parse(url));

  // TODO: should this be <Message> instead and handle [MessageType.error] here?
  Stream<dynamic> get stream => _conn.stream;
  Sink<dynamic> get sink => _conn.sink;
}


class MidHttpClient {
  final String url;

  MidHttpClient(this.url);
}

