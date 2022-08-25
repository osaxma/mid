import 'package:mid_server/mid_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

import 'router.dart';

void midServer(ServerConfig config) async {
  final router = generateRouter(config);

  final handler = Pipeline().addHandler(router);

  final server = await serve(
    handler,
    config.address,
    config.port,
    securityContext: config.securityContext,
    backlog: config.backlog,
    shared: config.shared,
  );

  if (config.printServerListeningOnPortMessage) {
    print('Server listening on port ${server.port}');
  }
}
