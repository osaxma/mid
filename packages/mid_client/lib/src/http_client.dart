import 'dart:convert';

import 'package:http/http.dart' as http;

import 'types.dart';

// TODO: figure out the best way to generate the server
// - Should we use http.post directly
//   - or create a single client? (if so, see: https://github.com/dart-lang/http/issues/422)
class MidHttpClient {
  final Uri uri;

  HeadersProvider? headersProvider;

  MidHttpClient(this.uri, this.headersProvider);

  Future<dynamic> executeHttp(Map<String, dynamic> args, String route) async {
    final body = json.encode(args);
    final headers = headersProvider?.call() ?? <String, String>{};
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

  void close() {
    // TODO: clean any resources here
  }
}
