import 'dart:async';

import 'package:mid_client/src/interceptor.dart';
import 'package:mid_protocol/mid_protocol.dart';

import 'http_client.dart';
import 'package:meta/meta.dart';
import 'ws_client.dart';

class BaseClient {
  Map<String, String> _headers;

  /// The current default headers that are used for each request
  Map<String, String> get headers => _headers;

  late final MidHttpClient _httpClient;

  late final MidWebSocketClient _wsClient;

  /// A wrapper client for the http and websocket clients of a mid project
  ///
  /// [url] is the server url. The client will parse the uri for both http and websocket.
  ///
  /// [initialHeaders] that will be used for sending http requests and establishing the
  /// websocket connection. The headers can be updated by invoking [updateHeaders] at any
  /// time. Alternatively, the headers for http requests can be modified by intercepting
  /// the requests (does not apply for websocket connection -- see [updateHeaders])
  ///
  /// [interceptors] a List of Interceptors that intercept http requests and responses
  ///
  /// Each [Interceptor.onRequest] is invoked before sending the request.
  /// And each [Interceptor.onResponse] is invoked before returning a response.
  ///
  /// The [interceptors] are invoked based on their order in the list starting from index 0.
  ///
  /// Important Notes:
  /// - Avoid changing ['content-type'] header as it'll be overwritten by the client.
  ///   For now, all requests will have "'content-type': 'application/json'".
  /// - All requests are sent using `http.post` at the time being.
  /// - The [interceptors] are not invoked on endpoints with a [Stream] retruen type
  ///   - see [updateHeaders] for more info.
  /// 
  /// [messageInterceptors] -- a list of interceptors to intercept messages between
  /// the server and the client of the websocket connection.  
  BaseClient({
    required String url,
    Map<String, String>? initialHeaders,
    List<Interceptor> interceptors = const [],
    List<MessageInterceptor> messageInterceptors = const [],
  }) : _headers = initialHeaders ?? {} {
    if (!url.contains('http')) {
      url = 'http://$url';
    }

    late final Uri httpURI, wsURI;
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

    _wsClient = MidWebSocketClient(uri: wsURI, headers: headers);
    _httpClient = MidHttpClient(uri: httpURI, headers: headers, interceptors: interceptors);
  }

  /// Updates a previously provided headers
  ///
  /// While the headers for http request can be updated using [Interceptor],
  /// this is the only method to update the headers for an active websocket connection.
  ///
  /// This method is useful for updating expirable values such as Authentication headers.
  /// In such scenario, it's important to update the headers before they expire to avoid
  /// the closure of an active subscription or losing the websocket connection (based on
  /// the server decision)
  ///
  /// If the headers don't need to be updated during the lifetime of this object, then calling
  /// this method is not necessary as the initially provided headers will be used throughout the
  /// lifetime of this object.
  @mustCallSuper
  void updateHeaders(Map<String, String> newHeaders) {
    _headers = newHeaders;
    _wsClient.updateHeaders(_headers);
    _httpClient.updateHeaders(_headers);
  }

  @protected
  Future<dynamic> executeHttp(Map<String, dynamic> args, String route) => _httpClient.executeHttp(args, route);

  @protected
  Stream<dynamic> executeStream(Map<String, dynamic> args, String route) => _wsClient.executeStream(args, route);

  @mustCallSuper
  void close() {
    _httpClient.close();
    _wsClient.close();
  }
}
