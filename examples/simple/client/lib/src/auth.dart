import 'dart:convert';

import 'package:client/src/models/session.dart';
import 'package:http/http.dart' as http;

typedef RequestHandler<T> = T Function(String url, Map<String, String> headers, String body);

class Auth {
  final String url;

  final Map<String, String> headers;

  Auth({
    required this.url,
    required this.headers,
  });

  Future<Session> createUserWithEmailAndPassword(String email, String password,
      [RequestHandler<Session>? handler]) async {
    final args = {
      'email': email,
      'password': password,
    };

    final body = json.encode(args);

    headers['content-type'] = 'application/json';
    print(headers);

    final res = await http.post(
      Uri.http(url, 'auth_server/create_user_with_email_and_password/'),
      headers: headers,
      body: body,
    );
    print(res.statusCode);

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    print(data);
    return Session.fromMap(data);
  }

  Future<Session> signInWithEmailAndPassword(String email, String password, {RequestHandler<Session>? handler}) async {
    final args = {
      'email': email,
      'password': password,
    };

    final body = json.encode(args);

    headers['content-type'] = 'application/json';
    print(headers);

    final res = await http.post(
      Uri.http(url, 'auth_server/sign_in_with_email_and_password/'),
      headers: headers,
      body: body,
    );
    print(res.statusCode);

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    print(data);
    return Session.fromMap(data);
  }
}
