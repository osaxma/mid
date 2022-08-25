import 'dart:io';

import 'package:mid_server/src/interceptor.dart';
import 'package:mid_server/mid_server.dart';

/// Server Configuration that will be passed to the shelf server
class ServerConfig {
  /// The list of handlers for handling http and websocket requests
  final List<BaseHandler> handlers;

  /// A list of of websocket messages interceptors
  final List<MessageInterceptorServer> messagesInterceptors;

  /// A List of http interceptors
  final List<HttpInterceptorServer> httpInterceptors;

  /// The IP Address used for the server
  /// See the documentation for [HttpServer.bind] and [HttpServer.bindSecure]
  /// for more details.
  final InternetAddress address;

  /// The port used for the server
  ///
  /// See the documentation for [HttpServer.bind] and [HttpServer.bindSecure]
  /// for more details.
  final int port;

  /// If a [securityContext] is provided an HTTPS server will be started.
  ///
  /// See the documentation for [HttpServer.bindSecure] for more details.
  final SecurityContext? securityContext;

  /// See the documentation for [HttpServer.bind] and [HttpServer.bindSecure]
  /// for more details.
  final int? backlog;

  /// See the documentation for [HttpServer.bind] and [HttpServer.bindSecure]
  /// for more details.
  final bool shared;

  /// If `true`, then upon the start of the server, the following message is printed:
  /// ```shell
  ///   Server listening on port XXXX
  /// ```
  /// Where XXXX is the [port] number. 
  /// 
  /// Defaults to `true`.
  final bool printServerListeningOnPortMessage;

  /// Create a custom server config
  ///
  /// These configs will be passed to mid server (i.e. a shelf server).
  ServerConfig({
    required this.handlers,
    required this.address,
    required this.port,
    this.httpInterceptors = const [],
    this.messagesInterceptors = const [],
    this.securityContext,
    this.backlog,
    this.shared = false,
    this.printServerListeningOnPortMessage = true,
  });
}
