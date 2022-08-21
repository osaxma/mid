import 'dart:async';

import 'package:http/http.dart';

/// A base client Interceptor for intercepting requests and responses
/// between the client and the server
/// 
/// Extend this class and override either method or both. By default, 
/// each interceptor return the same message when it's not overridden.
abstract class Interceptor {
  /// Intercept a request before it's sent to the server
  FutureOr<Request> onRequest(Request request) => request;

  /// Intercept a response when it arives from the server
  FutureOr<Response> onResponse(Response response) => response;
}
