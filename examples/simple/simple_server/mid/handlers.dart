/* 
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║                         GENERATED CODE BY mid                              ║
  ║                                                                            ║
  ║                         DO NOT MODIFY BY HAND                              ║
  ║                                                                            ║
  ╚════════════════════════════════════════════════════════════════════════════╝
*/

import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'endpoints.dart';
import 'serializers.dart';
import 'package:mid_auth/src/server/server.dart';

final Map<String, String> _defaultHeaders = {
  'content-type': 'application/json',
  // figure out how to make this defined by the EndPoint
  // 'Access-Control-Allow-Origin': '*',
};

Future<Router> generateRouter() async {
  final handlers = await getHandlers();
  final router = Router();
  for (final handler in handlers) {
    router.add(handler.verb, handler.route,
        (Request request) => _defaultHandler(request, handler));
  }
  return router;
}

Future<Response> _defaultHandler(
    Request request, FutureOrBaseHandler baseHandler) async {
  final contentType = request.headers['content-type'];

  if (contentType == null || !contentType.contains('application/json')) {
    return Response.badRequest(body: 'content type must be application/json');
  }

  final body = await request.readAsString();
  if (body.isEmpty) {
    return Response.badRequest(body: 'the request does not have a body');
  }

  try {
    final Map<String, dynamic> bodayMap = json.decode(body);
    final response = await baseHandler.handler(bodayMap);
    response.change(headers: _defaultHeaders);
    return response;
  } catch (e) {
    return Response.badRequest(body: 'failed to decode request body $e');
  }
}

abstract class FutureOrBaseHandler {
  /// the full route to the handler
  String get route;

  /// The request handler
  FutureOr<Response> handler(
      Map<String, dynamic>
          map); // need importing async =>  import 'dart:async';

  /// The HTTP verb
  // for now only post is used for all types of requests
  final String verb = 'POST';
}

abstract class StreamBaseHandler {
  /* WIP */
}

class AuthServerCreateUserWithEmailAndPasswordHandler
    extends FutureOrBaseHandler {
  final Auth authserver;
  AuthServerCreateUserWithEmailAndPasswordHandler(this.authserver);

  @override
  String get route => '/auth_server/create_user_with_email_and_password/';
  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    final email = map['email'] as String;
    final password = map['password'] as String;

    try {
      final result = await authserver.createUserWithEmailAndPassword(
        email,
        password,
      );

      return Response.ok(json.encode(SessionSerializer.toMap(result)));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

class AuthServerSignInWithEmailAndPasswordHandler extends FutureOrBaseHandler {
  final Auth authserver;
  AuthServerSignInWithEmailAndPasswordHandler(this.authserver);

  @override
  String get route => '/auth_server/sign_in_with_email_and_password/';
  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    final email = map['email'] as String;
    final password = map['password'] as String;

    try {
      final result = await authserver.signInWithEmailAndPassword(
        email,
        password,
      );

      return Response.ok(json.encode(SessionSerializer.toMap(result)));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

class AuthServerSignOutHandler extends FutureOrBaseHandler {
  final Auth authserver;
  AuthServerSignOutHandler(this.authserver);

  @override
  String get route => '/auth_server/sign_out/';
  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    final jwt = map['jwt'] as String;
    final refreshToken = map['refreshToken'] as String;

    try {
      final result = await authserver.signOut(
        jwt,
        refreshToken,
      );

      return Response.ok(json.encode('ok'));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

class AuthServerSignOutAllHandler extends FutureOrBaseHandler {
  final Auth authserver;
  AuthServerSignOutAllHandler(this.authserver);

  @override
  String get route => '/auth_server/sign_out_all/';
  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    final jwt = map['jwt'] as String;

    try {
      final result = await authserver.signOutAll(
        jwt,
      );

      return Response.ok(json.encode('ok'));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

class AuthServerRefreshSessionHandler extends FutureOrBaseHandler {
  final Auth authserver;
  AuthServerRefreshSessionHandler(this.authserver);

  @override
  String get route => '/auth_server/refresh_session/';
  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    final jwt = map['jwt'] as String;
    final refreshToken = map['refreshToken'] as String;

    try {
      final result = await authserver.refreshSession(
        jwt,
        refreshToken,
      );

      return Response.ok(json.encode(SessionSerializer.toMap(result)));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

class AuthServerSendConfirmationEmailHandler extends FutureOrBaseHandler {
  final Auth authserver;
  AuthServerSendConfirmationEmailHandler(this.authserver);

  @override
  String get route => '/auth_server/send_confirmation_email/';
  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    final user = UserSerializer.fromMap(map['user']);

    try {
      final result = await authserver.sendConfirmationEmail(
        user,
      );

      return Response.ok(json.encode('ok'));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

class AuthServerConfirmEmailHandler extends FutureOrBaseHandler {
  final Auth authserver;
  AuthServerConfirmEmailHandler(this.authserver);

  @override
  String get route => '/auth_server/confirm_email/';
  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    final object = map['object'] as Object;

    try {
      final result = await authserver.confirmEmail(
        object,
      );

      return Response.ok(json.encode(result));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

class AuthServerRequestPasswordResetHandler extends FutureOrBaseHandler {
  final Auth authserver;
  AuthServerRequestPasswordResetHandler(this.authserver);

  @override
  String get route => '/auth_server/request_password_reset/';
  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    final email = map['email'] as String;

    try {
      final result = await authserver.requestPasswordReset(
        email,
      );

      return Response.ok(json.encode(result));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

class AuthServerChangePasswordHandler extends FutureOrBaseHandler {
  final Auth authserver;
  AuthServerChangePasswordHandler(this.authserver);

  @override
  String get route => '/auth_server/change_password/';
  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    final jwt = map['jwt'] as String;
    final oldPassword = map['oldPassword'] as String;
    final newPassword = map['newPassword'] as String;

    try {
      final result = await authserver.changePassword(
        jwt,
        oldPassword,
        newPassword,
      );

      return Response.ok(json.encode(result));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

class AuthServerGetPublicJWKHandler extends FutureOrBaseHandler {
  final Auth authserver;
  AuthServerGetPublicJWKHandler(this.authserver);

  @override
  String get route => '/auth_server/get_public_jwk/';
  @override
  Response handler(Map<String, dynamic> map) {
    try {
      final result = authserver.getPublicJWK();

      return Response.ok(json.encode(result));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

class AuthServerGetPublicKeyInPemFormatHandler extends FutureOrBaseHandler {
  final Auth authserver;
  AuthServerGetPublicKeyInPemFormatHandler(this.authserver);

  @override
  String get route => '/auth_server/get_public_key_in_pem_format/';
  @override
  Response handler(Map<String, dynamic> map) {
    try {
      final result = authserver.getPublicKeyInPemFormat();

      return Response.ok(json.encode(result));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

Future<List<FutureOrBaseHandler>> getHandlers() async {
  final list = await endpoints();
  final handlers = <FutureOrBaseHandler>[
    AuthServerCreateUserWithEmailAndPasswordHandler(list[0] as Auth),
    AuthServerSignInWithEmailAndPasswordHandler(list[0] as Auth),
    AuthServerSignOutHandler(list[0] as Auth),
    AuthServerSignOutAllHandler(list[0] as Auth),
    AuthServerRefreshSessionHandler(list[0] as Auth),
    AuthServerSendConfirmationEmailHandler(list[0] as Auth),
    AuthServerConfirmEmailHandler(list[0] as Auth),
    AuthServerRequestPasswordResetHandler(list[0] as Auth),
    AuthServerChangePasswordHandler(list[0] as Auth),
    AuthServerGetPublicJWKHandler(list[0] as Auth),
    AuthServerGetPublicKeyInPemFormatHandler(list[0] as Auth)
  ];

  return handlers;
}
