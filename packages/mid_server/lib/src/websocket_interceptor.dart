//  note: maybe passing the Request here isn't a good idea..
//        we could create common object between http/websocket called ConnectionData
//        where the package user can send data from client to server including auth if they wish too
//        This will avoid relying on shelf package and the Request class and give the package more freedom
//        in the future.
import 'package:mid/protocol.dart';

/// Implement this class to create custom interceptor(s) for the websocket connection
///
///
/// If [clientMessage] or [serverMessage] throws an exception, the connection will be
/// terminated.
abstract class MessageInterceptor {
  /// Intercept messages sent by the client to the server
  Message clientMessage(Message message);

  /// Intercept messages sent by the server to the client
  Message serverMessage(Message message);
}
