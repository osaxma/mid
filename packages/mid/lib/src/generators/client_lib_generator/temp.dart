// this is how the client would look like

import 'dart:io';

class MidClient {
  // TODO: use an implementation that works for all platforms 
  late final HttpClient _client;


  // TODO: should this be a callback function that provides up to date 
  //       headers? This is important since the client may outlive some
  //       values in the headers such as Tokens and whatnot.
  //       Another option is to have middlewares 
  late final Map<String, dynamic> defaultHeaders;


  /// 
  final String url;

  MidClient({
    required this.url,
    HttpClient? client,
    Map<String, dynamic>? defaultHeaders,
  }) {
    _client = client ?? HttpClient();
    this.defaultHeaders = defaultHeaders ?? {};
  }


  Object get api1 => Object();
  Object get api2 => Object();
  Object get api3 => Object();
}
