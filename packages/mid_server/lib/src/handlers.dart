import 'dart:async';
import 'package:shelf/shelf.dart';

abstract class StreamBaseHandler {
  /// the full route to the handler
  String get route;

  /// The request handler
  Stream<String> handler(Map<String, dynamic> map);
}

abstract class FutureOrBaseHandler {
  /// the full route to the handler
  String get route;

  /// The request handler
  FutureOr<Response> handler(Map<String, dynamic> map); // need importing async =>  import 'dart:async';

  /// The HTTP verb
  // for now only post is used for all types of requests
  final String verb = 'POST';
}
