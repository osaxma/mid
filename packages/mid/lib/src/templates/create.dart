/// project/bin/server.dart
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


/// User defined middlewares
/// 
/// 
/// Important Note: 
/// Any request for a websocket connection (i.e. `/ws` route), it will not contain client headers. 
/// Make sure to skip such requests.
/// 
/// Alternatively, use [MessageInterceptor] to intercept incoming [Message]s where [Message.type] is
/// [MessageType.updateHeaders] to authenticate client websocket connections. 
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
// ignore_for_file: $unusedImportLint
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

const unusedFieldLint = 'unused_field';
const unusedImportLint = 'unused_import';

/// Generates the following string assuming [lints] contains `unused_import` and `unused_field`:
///
/// ```
/// // ignore_for_file: unused_import, unused_field
/// ```
///
String generateIgnoreForFile(List<String> lints) {
  return '// ignore_for_file: ${lints.join(', ')}';
}
