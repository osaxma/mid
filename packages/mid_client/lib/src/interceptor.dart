import 'dart:async';

import 'package:http/http.dart';

/// A base client Interceptor for intercepting requests and responses
/// between the client and the server
/// 
/// Extend this class and override either method or both. By default,
/// the interceptor return the same request or response.
abstract class Interceptor {
  /// Intercept a request before it's sent to the server
  FutureOr<Request> onRequest(Request request) => request;

  /// Intercept a response when it arives from the server
  FutureOr<Response> onResponse(Response response) => response;
}
