import 'dart:async';

import 'package:mid_client/src/interceptor.dart';

import 'http_client.dart';
import 'ws_client.dart';

class BaseClient {
  /// A List of Interceptors that intercept requests and responses
  ///
  /// Each [Interceptor.onRequest] is invoked before sending the request.
  /// And each [Interceptor.onResponse] is invoked before returning a response.
  ///
  /// The [interceptors] are invoked in the list order starting from index 0.
  ///
  /// Important Notes:
  /// - Avoid supplying ['content-type'] header as it'll be overwritten by the client.
  ///   For now, all requests will have "'content-type': 'application/json'".
  /// - All requests are sent using `http.post` at the time being.
  /// - The [interceptors] are not invoked on endpoints with a [Stream] retruen type
  ///   - see [headersStreamProvider] for more info.
  final List<Interceptor> interceptors;

  /// A callback that provides a stream of headers for the websocket connection
  ///
  /// The stream should emit an event with valid headers immediately upon listening.
  /// The provided headers will be sent to the server to initialize the connection.
  ///
  /// Any subsequent headers will be sent to the server during the connection lifetime.
  ///
  /// When the websocket does not have any live stream (e.g. endpoints of Stream type),
  /// the subscription will be closed.
  ///
  /// Once a new connection is created (i.e. a Stream endpoint was invoked), then a new
  /// stream is requested from the [headersStreamProvider]. And the cycle continues.
  ///
  /// The main use case scenario for using `headersStreamProvider` is to update the
  /// Authentication headers, especially when a token may expire during a live connection.
  ///
  /// It's the responsability of the `Stream` provided by [headersStreamProvider] to emit
  /// such headers on a timely manner. The server Interceptors receive an event once a
  /// new header is received (i.e. `MessageType.updateHeaders`)
  ///
  /// If the headers do not contain any expirable values, then [headersStreamProvider] can
  /// be null, and the [defaultHeaders] will be sufficient.
  // this could be [MessagesInterceptor]
  final Stream<Map<String, String>> Function()? headersStreamProvider;

  /// The default headers that will be added to every request
  ///
  /// They'll also be used for the websocket connection in the absense of [headersStreamProvider].
  final Map<String, String> defaultHeaders;

  /// The Websocket URI from the given [url]
  late final Uri wsURI;

  /// The HTTP URI parsed from the given [url]
  late final Uri httpURI;

  late final MidHttpClient _httpClient;

  late final MidWebSocketClient _wsClient;

  void close() {
    _httpClient.close();
    _wsClient.close();
  }

  BaseClient({
    required String url,
    this.headersStreamProvider,
    Map<String, String>? defaultHeaders,
    this.interceptors = const [],
  }) : defaultHeaders = defaultHeaders ?? {} {
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
    _httpClient = MidHttpClient(uri: httpURI, defaultHeaders: this.defaultHeaders, interceptors: interceptors);
  }

  Future<dynamic> executeHttp(Map<String, dynamic> args, String route) => _httpClient.executeHttp(args, route);

  Stream<dynamic> executeStream(Map<String, dynamic> args, String route) => _wsClient.executeStream(args, route);
}
