/// project/bin/server.dart
// const binServerDotDart = '''
// import '../mid/server.dart';

// void main(List<String> args) => server(args);
// ''';

String getServerDotDartContent(String projectName) => '''
import 'dart:io';

import 'package:mid_server/mid_server.dart';
import 'package:${projectName}_server/mid/endpoints.dart';
import 'package:${projectName}_server/mid/middlewares.dart';
import 'package:${projectName}_server/mid/generated/handlers.dart';

Future<void> main(List<String> args) async {
  final endpts = await getEndPoints();

  final serverConfig = ServerConfig(
    futureOrHandlers: getFutureOrHandlers(endpts),
    streamHandlers: getStreamHandlers(endpts),
    middlewares: getMiddlewares(),
    // Use any available host or container IP (usually `0.0.0.0`).
    ip: InternetAddress.anyIPv4,
    // For running in containers, the PORT environment variable would be used.
    port: int.parse(Platform.environment['PORT'] ?? '8000'),
  );

  midServer(serverConfig);
}
''';

// /// `project/mid/server.dart` file
// const serverDotDart = r'''
// import 'dart:io';

// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart';

// import 'handlers.dart';
// import '../middlewares.dart';

// void server(List<String> args) async {
//   // Use any available host or container IP (usually `0.0.0.0`).
//   final ip = InternetAddress.anyIPv4;

//   final router = await generateRouter();

//   final middlewares = getMiddlewares();

//   Pipeline pipeline = Pipeline();
//   for(final middleware in middlewares) {
//     pipeline = pipeline.addMiddleware(middleware);
//   }

//   final handler = pipeline.addHandler(router);

//   // For running in containers, we respect the PORT environment variable.
//   final port = int.parse(Platform.environment['PORT'] ?? '8080');
//   final server = await serve(handler, ip, port);
//   print('Server listening on port ${server.port}');
// }
// ''';

/// `project/mid/endpoints.dart` file
const endpointsDotDart = '''
import 'package:mid/mid.dart';

Future<List<EndPoints>> getEndPoints() async {

  /* do any initializations here */

  return <EndPoints>[
    /* 
      Add the class instances here then run the following from the root of the project:
      ~> mid generate endpoints
     */
  ];
}
''';

/// `project/mid/middlewares.dart` file
const middleWaresDotDart = '''
import 'package:shelf/shelf.dart';

List<Middleware> getMiddlewares() {
  return <Middleware>[
    // the default shelf logger 
    logRequests(), 
    /* add any other middlewares here */
  ];
}

''';

/// `project/mid/handlers.dart` file
///
/// This file will be updated by `mid generate endpoints`
///
/// The following code is just to prevent errors in other files referencing it.
const handlersDotDart = '''
$ignoreUnusedImports
$generatedCodeMessage

import 'package:mid/mid.dart';
import 'package:mid_server/mid_server.dart';
import 'package:shelf_router/shelf_router.dart';

List<FutureOrBaseHandler> getFutureOrHandlers(List<EndPoints> endpoints) {
  final handlers = <FutureOrBaseHandler>[];

  return handlers;
}

List<StreamBaseHandler> getStreamHandlers(List<EndPoints> endpoints) {
  final handlers = <StreamBaseHandler>[];

  return handlers;
}


''';

const generatedCodeMessage = '''
/* 
  ╔════════════════════════════════════════════════════════════════════════════╗
  ║                         GENERATED CODE BY mid                              ║
  ║                                                                            ║
  ║                         DO NOT MODIFY BY HAND                              ║
  ║                                                                            ║
  ╚════════════════════════════════════════════════════════════════════════════╝
*/
''';


const ignoreUnusedImports = '''
// ignore_for_file: unused_import
''';