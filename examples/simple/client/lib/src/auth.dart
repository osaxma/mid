import 'dart:convert';

import 'package:client/src/mid_common.dart';
import 'package:client/src/models/session.dart';
import 'package:client/src/models/user.dart';
import 'package:http/http.dart' as http;

class Auth {
  final String url;

  /// A function that provides an up-to-date headers for each request
  ///
  // The choice of a callback here because
  final Map<String, String> Function() headersProvider;

  Auth({
    required this.url,
    required this.headersProvider,
  });

  Future<Session> createUserWithEmailAndPassword(String email, String password) async {
    final args = {
      'email': email,
      'password': password,
    };

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';
    print(headersProvider);

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

  Future<Session> signInWithEmailAndPassword(String email, String password) async {
    final args = {
      'email': email,
      'password': password,
    };

    final body = json.encode(args);

    final headers = headersProvider();

    headers['content-type'] = 'application/json';
    print(headersProvider);

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
