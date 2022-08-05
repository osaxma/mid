

// This is a draft of how the generated code would look like

import 'dart:async';
import 'dart:convert';

import '../../../../../components/mid_auth/lib/mid_auth.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../entrypoint.dart';

final Map<String, String> _defaultHeaders = {
  'Content-Type': 'application/json',
  // figure out how to make this defined by the EndPoint
  // 'Access-Control-Allow-Origin': '*',
};

// trying to dsicover how the generated code would look like
Future<Router> generateRouter() async {
  final handlers = await getHandlers();
  final router = Router();
  for (final handler in handlers) {
    router.add(handler.verb, handler.route, (Request request) => defaultHandler(request, handler));
  }
  return router;
}

// generated code
Future<List<BaseHandler>> getHandlers() async {
  final endpts = await entryPoint();
  final handlers = <BaseHandler>[
    AuthCreateUserWithEmailAndPasswordHandler(endpts[0] as AuthServer),
    AuthSignInWithEmailAndPasswordHandler(endpts[0] as AuthServer),
  ];

  return handlers;
}

Future<Response> defaultHandler(Request request, BaseHandler baseHandler) async {
  final contentType = request.headers['Content-Type'];

  if (contentType == null || contentType != 'application/json') {
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
    return Response.badRequest(body: 'failed to decode request body');
  }
}

abstract class BaseHandler {
  /// the full route to the handler
  String get route;

  /// The request handler
  Future<Response> handler(Map<String, dynamic> map);

  /// The HTTP verb
  // for now only post is used for all types of requests
  final String verb = 'POST';
}

// generated code
class AuthCreateUserWithEmailAndPasswordHandler extends BaseHandler {
  final AuthServer instance;

  @override
  String get route => 'auth/createUserWithEmailAndPassword';

  AuthCreateUserWithEmailAndPasswordHandler(this.instance);

  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    final email = map['email'] as String;
    final password = map['password'] as String;
    try {
      final result = await instance.createUserWithEmailAndPassword(email, password);
      return Response.ok(result.toJson());
    } catch (e) {
      return Response.badRequest(body: e);
    }
  }
}

class AuthSignInWithEmailAndPasswordHandler extends BaseHandler {
  final AuthServer instance;
  AuthSignInWithEmailAndPasswordHandler(this.instance);

  @override
  String get route => 'auth/signInWithEmailAndPassword';
  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    final email = map['email'] as String;
    final password = map['password'] as String;
    try {
      final result = await instance.signInWithEmailAndPassword(email, password);
      return Response.ok(result.toJson());
    } catch (e) {
      return Response.badRequest(body: e);
    }
  }
}

String generateHandlerClass(
  String className,
  String handlerClassType,
  String methodName,
  String route,
  String assignments,
  String methodInvokation,
) {
  // TODO: how to handle the method ? should we force named parameters?
  //       maybe a separate function should handle 
  return '''
class $className extends BaseHandler {
  final $handlerClassType instance;
  $className(this.instance);

  @override
  String get route => $route;
  @override
  Future<Response> handler(Map<String, dynamic> map) async {
    $assignments
    try {
      final result = await instance.$methodInvokation;
      // what if the return type is just a basic type? 
      return Response.ok(result.toJson());
    } catch (e) {
      return Response.badRequest(body: e);
    }
  }
}
''';
}
