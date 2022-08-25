import 'package:mid_common/mid_common.dart';
import 'package:shelf/shelf.dart';

extension ResponsEx on Response {
  /// inject the request id that came from the client request
  Response injectRequestID(String id) {
    return change(headers: {requestIdKey: id});
  }

  /// get the request id that came from the client request 
  String? get requestID => headers[requestIdKey];
}

extension RequestEx on Request {
  /// get the request id that came with the client side
  String? get requestID => headers[requestIdKey];
}
