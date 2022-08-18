import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

void midServer(Router router, List<Middleware> middlewares) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  Pipeline pipeline = Pipeline();
  for (final middleware in middlewares) {
    pipeline = pipeline.addMiddleware(middleware);
  }

  final handler = pipeline.addHandler(router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8000');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
