import 'dart:io';

import 'package:mid_protocol/mid_protocol.dart';
import 'package:shelf/shelf.dart';

import 'package:mid_server/mid_server.dart';

/// Server Configuration that will be passed to the shelf server
class ServerConfig {
  /// The list of handlers for handling http and websocket requests
  final List<BaseHandler> handlers;

  /// A list of [Middleware]s that are passed to shelf server
  final List<Middleware> middlewares;

  /// A list of of websocket messages interceptors
  final List<MessageInterceptor> messagesInterceptor;

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

  ServerConfig({
    required this.handlers,
    required this.address,
    required this.port,
    this.middlewares = const [],
    this.messagesInterceptor = const [],
    this.securityContext,
    this.backlog,
    this.shared = false,
  });
}
