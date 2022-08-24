import 'package:shelf/shelf.dart';

export 'package:shelf/shelf.dart' show Request, Response;
export 'extensions.dart';

/// A base server Interceptor for intercepting requests and responses
/// between the client and the server
///
/// Extend this class and override either method or both. By default,
/// the interceptor return the same request or response.
///
/// When modifying
abstract class HttpInterceptor {
  /// Intercept a client request before it's sent to the handler.
  Future<Request> onRequest(Request request) async => request;

  /// Intercept a response before it's sent to the client.
  Future<Response> onResponse(Response response) async => response;
}
