/// project/bin/server.dart
String getServerDotDartContent(String projectName) => '''
import 'dart:io';

import 'package:mid_server/mid_server.dart';
import 'package:${projectName}_server/mid/generated/handlers.dart';

Future<void> main(List<String> args) async {

  // Get the generated server handlers 
  final handlers = await getHandlers(); 

  // Create the server configurations
  final serverConfig = ServerConfig(
    handlers: handlers, 

    // Use any available host or container IP (usually `0.0.0.0`).
    address: InternetAddress.anyIPv4,
    
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
import '../endpoints.dart';

$getHandlersFunction

List<FutureOrBaseHandler> _getFutureOrHandlers(List<EndPoints> endpoints) {
  final handlers = <FutureOrBaseHandler>[];

  return handlers;
}

List<StreamBaseHandler> _getStreamHandlers(List<EndPoints> endpoints) {
  final handlers = <StreamBaseHandler>[];

  return handlers;
}

''';

const getHandlersFunction = '''
Future<List<BaseHandler>> getHandlers() async {
  final endpoints = await getEndPoints();
  return [
    ..._getFutureOrHandlers(endpoints),
    ..._getStreamHandlers(endpoints),
  ];
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
final unnecessaryImport = 'unnecessary_import';

/// Generates the following string assuming [lints] contains `unused_import` and `unused_field`:
///
/// ```
/// // ignore_for_file: unused_import, unused_field
/// ```
///
String generateIgnoreForFile(List<String> lints) {
  return '// ignore_for_file: ${lints.join(', ')}';
}
