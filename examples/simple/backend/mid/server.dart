import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

import 'handlers.dart';
import 'middlewares.dart';

void server(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  final router = await generateRouter();

  final middlewares = getMiddlewares();

  Pipeline pipeline = Pipeline();
  for(final middleware in middlewares) {
    pipeline = pipeline.addMiddleware(middleware);
  }

  final handler = pipeline.addHandler(router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
