import 'http_client.dart';
import 'types.dart';
import 'ws_client.dart';

class BaseClient {
  /// A function that should provide an up-to-date headers for each request
  ///
  /// e.g. Bearer Authentication (token)
  // TODO: this is a temp solution until we support either interceptors or a custom `ConnectionData`
  //       speaking of which, a custom `ConnectionData` is preferable since it can be used with both
  //       http and websocket as well as hide the `http` stuff under the hood.
  final HeadersProvider? headersProvider;

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

  BaseClient({required String url, this.headersProvider}) {
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
