import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mid_common/mid_common.dart';
import 'package:mid_client/src/interceptor.dart';

// TODO: test if this approach won't cause issues
//       this is a long lived object so the client
//       may be alive the entire life of the app
//       there are some issues mentioned here:
//        https://github.com/dart-lang/http/issues/422)
class MidHttpClient extends http.BaseClient {
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
    _headers[contentTypeKey] = 'application/json';
    _headers[requestIdKey] = generateRandomID(20);

    http.Response response = await post(
      uri.replace(path: route),
      headers: _headers,
      body: body,
    );

    for (var interceptor in interceptors) {
      response = await interceptor.onResponse(response);
    }

    if (response.statusCode >= 400) {
      throw Exception(response.body);
    }

    final data = json.decode(response.body);
    return data;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    for (var interceptor in interceptors) {
      request = await interceptor.onRequest(request as http.Request);
    }
    return request.send();
  }

  @override
  // ignore: unnecessary_overrides
  void close() {
    // TODO: clean any resources here
    super.close();
  }
}
