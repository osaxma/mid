import 'package:shelf/shelf.dart';

List<Middleware> getMiddlewares() {
  return <Middleware>[
    // the default shelf logger 
    logRequests(), 
    /* add any other middlewares here */
  ];
}

