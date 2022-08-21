import 'message.dart';

/// An interface for intercepting websocket messages between server and client
///
/// If [clientMessage] or [serverMessage] throws an exception, the connection will be
/// terminated and the [Message] will not reach its destination.
///
/// Extend this class and override either method or both. By default, each interceptor
/// return the same message when it's not overridden.
abstract class MessageInterceptor {
  /// Intercept messages sent by the client to the server
  Message clientMessage(Message message) => message;

  /// Intercept messages sent by the server to the client
  Message serverMessage(Message message) => message;
}
