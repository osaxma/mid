import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:mid/protocol.dart';

class BaseClient {
  /// A function that should provide an up-to-date headers for each request
  ///
  /// e.g. Bearer Authentication (token)
  // TODO: this is a temp solution until we support either interceptors or a custom `ConnectionData`
  //       speaking of which, a custom `ConnectionData` is preferable since it can be used with both
  //       http and websocket as well as hide the `http` stuff under the hood.
  final Map<String, String> Function() headersProvider;

  /// The Websocket URI from the given [url]
  late final Uri wsURI;

  /// The HTTP URI parsed from the given [url]
  late final Uri httpURI;

  late final MidHttpClient _httpClient;

  late final MidWebSocketClient _wsClient;

  BaseClient({required String url, required this.headersProvider}) {
    if (!url.contains('http')) {
      url = 'http://$url';
    }
    try {
      httpURI = Uri.parse(url);
    } catch (e) {
      throw Exception('Uri.parse Failed to parse: $url due to the following error: $e');
    }

    if (httpURI.scheme == 'https') {
      wsURI = httpURI.replace(scheme: 'wss', path: 'ws');
    } else {
      wsURI = httpURI.replace(scheme: 'ws', path: 'ws');
    }

    _wsClient = MidWebSocketClient(uri: wsURI);
    _httpClient = MidHttpClient(httpURI, headersProvider);
  }

  Future<dynamic> executeHttp(Map<String, dynamic> args, String route) => _httpClient.executeHttp(args, route);

  Stream<dynamic> executeStream(Map<String, dynamic> args, String route) => _wsClient.executeStream(args, route);
}

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

// TODO: figure out the best way to generate the server
// - Should we use http.post directly
//   - or create a single client? (if so, see: https://github.com/dart-lang/http/issues/422)
class MidHttpClient {
  final Uri uri;

  /// A function that should provide an up-to-date headers for each request
  ///
  /// e.g. Bearer Authentication (token)
  // TODO: this is a temp solution until we support either interceptors or a custom `ConnectionData`
  //       speaking of which, a custom `ConnectionData` is preferable since it can be used with both
  //       http and websocket as well as hide the `http` stuff under the hood.
  final Map<String, String> Function() headersProvider;

  MidHttpClient(this.uri, this.headersProvider);

  Future<dynamic> executeHttp(Map<String, dynamic> args, String route) async {
    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      uri.replace(path: route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return data;
  }
}
