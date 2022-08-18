//  note: maybe passing the Request here isn't a good idea..
//        we could create common object between http/websocket called ConnectionData
//        where the package user can send data from client to server including auth if they wish too
//        This will avoid relying on shelf package and the Request class and give the package more freedom
//        in the future.
import 'package:mid/protocol.dart';
import 'package:shelf/shelf.dart';

/// Implement this class to create custom interceptor(s) for the websocket connection
///
///
/// If [clientMessage] or [serverMessage] throws an exception, the connection will be
/// terminated.
abstract class MessageInterceptor {
  /// Intercept messages sent by the client to the server
  ///
  /// The [request] is the initial request that was used to establish the connection
  Message clientMessage(Message message, Request request);

  /// Intercept messages sent by the server to the client
  ///
  /// The [request] is the initial request that was used to establish the connection
  Message serverMessage(Message message, Request request);
}
