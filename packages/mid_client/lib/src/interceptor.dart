import 'dart:async';

import 'package:http/http.dart';
import 'package:mid_protocol/mid_protocol.dart';

/// A base client Interceptor for intercepting requests and responses
/// between the client and the server
/// 
/// Extend this class and override either method or both. By default, 
/// each interceptor return the same message when it's not overridden.
abstract class HttpInterceptorClient {
  /// Intercept a request before it's sent to the server
  Future<Request> onRequest(Request request) async => request;

  /// Intercept a response when it arives from the server
  Future<Response> onResponse(Response response) async => response;
}



/// An interface for intercepting websocket messages between server and client
///
/// If [clientMessage] or [serverMessage] throws an exception, the connection will be
/// terminated and the [Message] will not reach its destination.
///
/// Extend this class and override either method or both. By default, each interceptor
/// return the same message when it's not overridden.
abstract class MessageInterceptorClient {
  /// Intercept messages sent by the client to the server
  Message clientMessage(Message message) => message;

  /// Intercept messages sent by the server to the client
  Message serverMessage(Message message) => message;
}
