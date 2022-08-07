
/// project/bin/server.dart
const binServerDotDart = '''
import '../mid/server.dart';

void main(List<String> args) => server(args);
''';

/// `project/mid/server.dart` file
const serverDotDart = r'''
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
''';


/// `project/mid/entrypoint.dart` file
const entryPointDotDart = '''

Future<List<Object>> entryPoint() async {

  /* do any initializations here */

  return <Object>[
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

$generatedCodeMessage


import 'package:shelf_router/shelf_router.dart';

Future<Router> generateRouter() async {
  // The code here will be generated after running `mid generate endpoints` 
  throw UnimplementedError;
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



const configTemplate = '''
{
    "client": {
        // the target directory where the client project will be created
        "target_directory": null,
        // the project name (defaults to "client")
        "project_name": "client"
    },
    "server": {}
}
''';