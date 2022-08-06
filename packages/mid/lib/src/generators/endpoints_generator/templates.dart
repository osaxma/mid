const shelfImport = "import 'package:shelf/shelf.dart';";
const asyncImport = "import 'dart:async';";

const futureOrBaseHandler = '''
abstract class FutureOrBaseHandler {
  /// the full route to the handler
  String get route;

  /// The request handler
  FutureOr<Response> handler(Map<String, dynamic> map); // need importing async =>  import 'dart:async';

  /// The HTTP verb
  // for now only post is used for all types of requests
  final String verb = 'POST';
}
''';

const streamBaseHandler = '''
abstract class StreamBaseHandler {
  /* WIP */
}
''';

/// Generate a class extending BaseHandler (defined at [futureOrBaseHandler])
///
/// Note the assignments String containing all variable assignments:
/// ```dart
///   final var1 = map['key1'] as Type;
///   final var2 = map['key2'] as Type;
///   ....
///   final varN = map['keyN'] as Type;
/// ```
/// 
/// The [methodInvocation] should be the call to the instance:
/// ```dart
/// final result = await classInstanceName.methodName(arguments);
/// ```
/// 
/// The [responseBody] is whatever should be returned -- for instance:
/// ```dart
/// result.toJson()
/// // or
/// result // if a basic type
/// ```
/// 
String generateHandlerClass({
  required String className,
  required String classInstanceName,
  required String handlerClassType,
  required String route,
  required String assignments,
  required String methodInvocation,
  required String responseBody,
  required bool isFuture,
}) {
  // TODO: how to handle the method ? should we force named parameters?
  //       maybe a separate function should handle

  final returnType = isFuture ? 'Future<Response>' : 'Response';
  final asyncKeyWord = isFuture ? 'async' : '';


  return '''
class $className extends FutureOrBaseHandler {
  final $handlerClassType $classInstanceName;
  $className(this.$classInstanceName);

  @override
  String get route => $route;
  @override
  $returnType handler(Map<String, dynamic> map) $asyncKeyWord {
    $assignments
    try {
      $methodInvocation
      return Response.ok($responseBody);
    } catch (e) {
      return Response.badRequest(body: e);
    }
  }
}
''';
}
