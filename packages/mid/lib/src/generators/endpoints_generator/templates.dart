const entryPointImport = "import 'entrypoint.dart';";
const shelfImport = "import 'package:shelf/shelf.dart';";
const shelfRouterImport = "import 'package:shelf_router/shelf_router.dart';";
const asyncImport = "import 'dart:async';";
const dartConvertImport = "import 'dart:convert';";

const handlersListName = "handlers";

const generateRouterMethod = r''' 

final Map<String, String> _defaultHeaders = {
  'Content-Type': 'application/json',
  // figure out how to make this defined by the EndPoint
  // 'Access-Control-Allow-Origin': '*',
};

Future<Router> generateRouter() async {
  final handlers = await getHandlers();
  final router = Router();
  for (final handler in handlers) {
    router.add(handler.verb, handler.route, (Request request) => _defaultHandler(request, handler));
  }
  return router;
}

Future<Response> _defaultHandler(Request request, FutureOrBaseHandler baseHandler) async {
  final contentType = request.headers['Content-Type'];

  if (contentType == null || contentType != 'application/json') {
    return Response.badRequest(body: 'content type must be application/json');
  }

  final body = await request.readAsString();
  if (body.isEmpty) {
    return Response.badRequest(body: 'the request does not have a body');
  }

  try {
    final Map<String, dynamic> bodayMap = json.decode(body);
    final response = await baseHandler.handler(bodayMap);
    response.change(headers: _defaultHeaders);
    return response;
  } catch (e) {
    return Response.badRequest(body: 'failed to decode request body $e');
  }
}
''';

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
