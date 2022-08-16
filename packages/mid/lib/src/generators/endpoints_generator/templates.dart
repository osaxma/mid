const endpointsImport = "import 'endpoints.dart';";
const serializersImport = "import 'serializers.dart';";
const shelfImport = "import 'package:shelf/shelf.dart';";
const shelfRouterImport = "import 'package:shelf_router/shelf_router.dart';";
const asyncImport = "import 'dart:async';";
const dartConvertImport = "import 'dart:convert';";

const handlersListName = "handlers";

const generateRouterMethod = r''' 

final Map<String, String> _defaultHeaders = {
  'content-type': 'application/json',
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
  final contentType = request.headers['content-type'];

  if (contentType == null || !contentType.contains('application/json')) {
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
