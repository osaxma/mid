import 'package:mid_server/mid_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router generateRouter(ServerConfig config) {
  final router = Router();
  for (final handler in config.futureOrHandlers) {
    router.add(handler.verb, handler.route, (Request request) => defaultHandler(request, handler));
  }

  // add websocket handler
  final websocketHandler = WebsocketHandler(handlers: config.streamHandlers, interceptors: config.messagesInterceptor);
  router.get('/ws', websocketHandler.wsHandler);
  return router;
}
