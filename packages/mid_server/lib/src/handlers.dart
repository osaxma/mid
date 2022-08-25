import 'dart:async';
import 'dart:convert';

import 'interceptor.dart';

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

class DefaultHttpHandler {
  final List<HttpInterceptorServer> interceptors;

  const DefaultHttpHandler(this.interceptors);

  Future<Response> handle(
    Request request,
    FutureOrBaseHandler baseHandler,
  ) async {
    final requestID = request.requestID ?? '';
    try {
      request = await _interceptRequests(request);
    } catch (e) {
      if (e is Response) {
        return _interceptResponse(e, requestID);
      } else {
        throw _interceptResponse(Response.badRequest(body: e.toString()), requestID);
      }
    }

    final contentType = request.headers['content-type'];

    if (contentType == null || !contentType.contains('application/json')) {
      return _interceptResponse(Response.badRequest(body: 'content type must be application/json'), requestID);
    }

    late final String body;
    try {
      body = await request.readAsString();
    } catch (e) {
      return _interceptResponse(Response.internalServerError(body: e.toString()), requestID);
    }

    if (body.isEmpty) {
      return _interceptResponse(Response.badRequest(body: 'the request does not have a body'), requestID);
    }

    try {
      final Map<String, dynamic> bodayMap = json.decode(body);
      final result = await baseHandler.handler(bodayMap);
      final response = Response.ok(result);
      response.change(headers: _defaultHeaders);
      return _interceptResponse(response, requestID);
    } catch (e) {
      return _interceptResponse(Response.badRequest(body: 'failed to decode request body $e'), requestID);
    }
  }

  Future<Request> _interceptRequests(Request request) async {
    for (var interceptor in interceptors) {
      request = await interceptor.onRequest(request);
    }

    return request;
  }

  Future<Response> _interceptResponse(Response response, String requestID) async {
    response = response.injectRequestID(requestID);
    for (var interceptor in interceptors) {
      try {
        response = await interceptor.onResponse(response);
      } catch (e) {
        // it would be wild if a response interceptor throws a response instead of returning one
        // but who knows.
        if (e is Response) {
          response = e;
        } else {
          // TODO: document that the logger response should be the last one in the list of
          //       interceptors in order to log any error that may be caused by the interceptor
          //       itself and supress error messages that should not be returned to the client
          response = Response.internalServerError(body: e.toString());
        }
      }
    }
    return response;
  }
}
