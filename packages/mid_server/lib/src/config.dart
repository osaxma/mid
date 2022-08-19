import 'dart:io';

import 'package:shelf/shelf.dart';

import 'package:mid_server/mid_server.dart';

class ServerConfig {
  final List<StreamBaseHandler> streamHandlers;
  final List<FutureOrBaseHandler> futureOrHandlers;
  final List<Middleware> middlewares;

  final InternetAddress ip;
  final int port;
  
  ServerConfig({
    required this.streamHandlers,
    required this.futureOrHandlers,
    required this.middlewares,
    required this.ip,
    required this.port,
  });
}
