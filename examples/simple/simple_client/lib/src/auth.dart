import 'dart:convert';

import 'package:client/src/models/session.dart';
import 'package:client/src/models/user.dart';
import 'package:http/http.dart' as http;


class AuthServerClient {
  AuthServerClient({required this.url, required this.headersProvider});

  /// The server URL
  final String url;

  /// A function that should provide an up-to-date headers for each request
  ///
  /// e.g. Bearer Authentication (token)
  final Map<String, String> Function() headersProvider;

  Future<Session> createUserWithEmailAndPassword(
      String email, String password) async {
    final args = {
      'email': email,
      'password': password,
    };

    final route = '/auth_server/create_user_with_email_and_password/';

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return Session.fromMap(data);
  }

  Future<Session> signInWithEmailAndPassword(
      String email, String password) async {
    final args = {
      'email': email,
      'password': password,
    };

    final route = '/auth_server/sign_in_with_email_and_password/';

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return Session.fromMap(data);
  }

  Future<void> signOut(String jwt, String refreshToken) async {
    final args = {
      'jwt': jwt,
      'refreshToken': refreshToken,
    };

    final route = '/auth_server/sign_out/';

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return;
  }

  Future<void> signOutAll(String jwt) async {
    final args = {
      'jwt': jwt,
    };

    final route = '/auth_server/sign_out_all/';

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return;
  }

  Future<Session> refreshSession(String jwt, String refreshToken) async {
    final args = {
      'jwt': jwt,
      'refreshToken': refreshToken,
    };

    final route = '/auth_server/refresh_session/';

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return Session.fromMap(data);
  }

  Future<void> sendConfirmationEmail(User user) async {
    final args = {
      'user': user,
    };

    final route = '/auth_server/send_confirmation_email/';

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return;
  }

  Future<Object> confirmEmail(Object object) async {
    final args = {
      'object': object,
    };

    final route = '/auth_server/confirm_email/';

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return data as Object;
  }

  Future<Object> requestPasswordReset(String email) async {
    final args = {
      'email': email,
    };

    final route = '/auth_server/request_password_reset/';

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return data as Object;
  }

  Future<Object> changePassword(
      String jwt, String oldPassword, String newPassword) async {
    final args = {
      'jwt': jwt,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };

    final route = '/auth_server/change_password/';

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return data as Object;
  }

  Future<Map<String, dynamic>> getPublicJWK() async {
    final args = {};

    final route = '/auth_server/get_public_jwk/';

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return data;
  }

  Future<String> getPublicKeyInPemFormat() async {
    final args = {};

    final route = '/auth_server/get_public_key_in_pem_format/';

    final body = json.encode(args);
    final headers = headersProvider();
    headers['content-type'] = 'application/json';

    final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

    if (res.statusCode >= 400) {
      throw Exception(res.body);
    }

    final data = json.decode(res.body);
    return data as String;
  }
}
