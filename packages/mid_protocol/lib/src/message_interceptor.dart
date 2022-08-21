import 'message.dart';

/// Implement this class to create custom interceptor(s) for the websocket messages
///
///
/// If [clientMessage] or [serverMessage] throws an exception, the connection will be
/// terminated and the [Message] will not reach its destination.
abstract class MessageInterceptor {
  /// Intercept messages sent by the client to the server
  Message clientMessage(Message message) => message;

  /// Intercept messages sent by the server to the client
  Message serverMessage(Message message) => message;
}
