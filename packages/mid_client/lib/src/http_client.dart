import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mid_client/src/interceptor.dart';

// TODO: figure out the best way to generate the server
// - Should we use http.post directly
//   - or create a single client? (if so, see: https://github.com/dart-lang/http/issues/422)
class MidHttpClient {
  final Uri uri;

  late Map<String, String> _headers;

  void updateHeaders(Map<String, String> newHeaders) {
    _headers = {...newHeaders};
    _headers.removeWhere((key, value) => key.toLowerCase() == 'content-type');
  }

  final List<Interceptor> interceptors;

  MidHttpClient({
    required this.uri,
    required Map<String, String> headers,
    required this.interceptors,
  }) {
    updateHeaders(headers);
  }

  Future<dynamic> executeHttp(Map<String, dynamic> args, String route) async {
    final body = json.encode(args);
    _headers.removeWhere((key, value) => key.toLowerCase() == 'content-type');
    _headers['content-type'] = 'application/json';

    final res = await http.post(
      uri.replace(path: route),
      headers: _headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return data;
  }

  void close() {
    // TODO: clean any resources here
  }
}
