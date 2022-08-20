import 'package:http/http.dart';

/// A base client Interceptor for intercepting requests and responses
/// between the client and the server
abstract class Interceptor {
  /// Intercept a request before it's sent to the server
  Request onRequest(Request request);

  /// Intercept a response when it arives from the server
  Response onResponse(Response request);
}
