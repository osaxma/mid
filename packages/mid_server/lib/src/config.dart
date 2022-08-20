import 'dart:io';

import 'package:shelf/shelf.dart';

import 'package:mid_server/mid_server.dart';

/// Server Configuration that will be passed to the shelf server
class ServerConfig {
  /// The list of [Stream] handlers to be handled by the websocket handler
  final List<StreamBaseHandler> streamHandlers;

  /// The list of [FutureOr] handlers to be handled by the http handler
  final List<FutureOrBaseHandler> futureOrHandlers;

  /// A list of [Middleware]s that are passed to shelf server
  final List<Middleware> middlewares;

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
    required this.streamHandlers,
    required this.futureOrHandlers,
    required this.middlewares,
    required this.address,
    required this.port,
    this.securityContext,
    this.backlog,
    this.shared = false,
  });
}
