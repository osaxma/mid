import 'package:mid_server/mid_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

import 'router.dart';

void midServer(ServerConfig config) async {
  final router = generateRouter(config.futureOrHandlers, config.streamHandlers);

  Pipeline pipeline = Pipeline();
  for (final middleware in config.middlewares) {
    pipeline = pipeline.addMiddleware(middleware);
  }

  final handler = pipeline.addHandler(router);

  final server = await serve(handler, config.ip, config.port);
  print('Server listening on port ${server.port}');
}
