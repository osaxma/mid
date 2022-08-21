import 'dart:async';

import 'package:shelf/shelf.dart';

/// A base server Interceptor for intercepting requests and responses
/// between the client and the server
///
/// Extend this class and override either method or both. By default,
/// the interceptor return the same request or response.
///
/// When modifying
abstract class BaseInterceptor {
  /// Intercept a client request before it's sent to the handler.
  FutureOr<Request> onRequest(Request request) => request;

  /// Intercept a response before it's sent to the client.
  FutureOr<Response> onResponse(Response response) => response;
}
