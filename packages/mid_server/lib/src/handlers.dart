import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';

abstract class BaseHandler {
  /// the full route to the handler
  String get route;
}

/// A base handler for any endpoint that returns a [Stream]
abstract class StreamBaseHandler implements BaseHandler {
  /// The request handler
  Stream<String> handler(Map<String, dynamic> map);
}

/// A base handler for any endpoint that returns a [Future] or [Type] i.e. [FutureOr]
abstract class FutureOrBaseHandler implements BaseHandler {
  /// The request handler
  FutureOr<String> handler(Map<String, dynamic> map);

  /// The HTTP verb
  // for now only post is used for all types of requests
  final String verb = 'POST';
}

final Map<String, String> _defaultHeaders = {
  'content-type': 'application/json',
  // figure out how to make this defined by the EndPoint
  // 'Access-Control-Allow-Origin': '*',
};

Future<Response> defaultHandler(Request request, FutureOrBaseHandler baseHandler) async {
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
    final result = await baseHandler.handler(bodayMap);
    final response = Response.ok(result);
    response.change(headers: _defaultHeaders);
    return response;
  } catch (e) {
    return Response.badRequest(body: 'failed to decode request body $e');
  }
}
