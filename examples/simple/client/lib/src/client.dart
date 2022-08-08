// this is how the client would look like

typedef HeadersProvider = Map<String, String> Function();

class MidClient {
  /// A function that provides an up-to-date headers for each request
  /// 
  // The choice of a callback here because
  late final HeadersProvider _headersProvider;

  /// The server URL
  final String url;

  MidClient({
    required this.url,
    HeadersProvider? headersProvider,
  }) {
    _headersProvider = headersProvider ?? () => <String, String>{};
  }

  Object get api1 => Object();
  Object get api2 => Object();
  Object get api3 => Object();
}
