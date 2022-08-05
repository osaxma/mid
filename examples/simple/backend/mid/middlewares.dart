import 'package:shelf/shelf.dart';

List<Middleware> getMiddlewares() {
  return <Middleware>[
    logRequests(),
    /* add your middlewares here */
  ];
}
