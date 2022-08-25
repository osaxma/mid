import 'package:shelf/shelf.dart';
import 'package:mid_protocol/mid_protocol.dart';

// this will help with autocomplete 
// see: https://github.com/Dart-Code/Dart-Code/issues/4116
export 'package:shelf/shelf.dart' show Request, Response;
export 'extensions.dart';

/// A base server Interceptor for intercepting requests and responses
/// between the client and the server
///
/// Extend this class and override either method or both. By default,
/// the interceptor return the same request or response.
///
/// When modifying
abstract class HttpInterceptorServer {
  /// Intercept a client request before it's sent to the handler.
  Future<Request> onRequest(Request request) async => request;

  /// Intercept a response before it's sent to the client.
  Future<Response> onResponse(Response response) async => response;
}

/// An interface for intercepting websocket messages between server and client
///
/// If [clientMessage] or [serverMessage] throws an exception, the connection will be
/// terminated and the [Message] may not reach its destination in the server.
///
/// Extend this class and override either method or both. By default, each interceptor
/// return the same message when it's not overridden.
abstract class MessageInterceptorServer {
  /// Intercept messages sent by the client to the server
  ///
  /// The [headers] refers to the latest available headers either from [ConnectionInitMessage]
  /// or from a [ConnectionUpdateMessage] (i.e. `BaseClient.updateHeaders`). The headers can
  /// be used for validation. If the interceptor may returns an [ErrorMessage] or throw one. 
  Message clientMessage(Message message, Map<String, String> headers) => message;

  /// Intercept messages sent by the server to the client
  Message serverMessage(Message message) => message;
}
