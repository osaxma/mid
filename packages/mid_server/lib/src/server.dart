import 'package:mid_server/mid_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

import 'router.dart';

void midServer(ServerConfig config) async {
  final router = generateRouter(config);

  Pipeline pipeline = Pipeline();
  // ignore: deprecated_member_use_from_same_package
  for (final middleware in config.middlewares) {
    pipeline = pipeline.addMiddleware(middleware);
  }

  final handler = pipeline.addHandler(router);

  final server = await serve(
    handler,
    config.address,
    config.port,
    securityContext: config.securityContext,
    backlog: config.backlog,
    shared: config.shared,
  );
  print('Server listening on port ${server.port}');
}
