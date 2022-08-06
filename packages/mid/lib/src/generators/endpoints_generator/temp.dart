// input

import 'dart:async';

class App {

  // example non-async function
  String getAppVersion() {
    return '0.1.1';
  }
  
  // example return serializable with required named argument
  Future<Data> getUserData({required String userID}) async {
    return Data(id: 1, data: 'some data');
  }
  // example stream function with positional argument
  Future<Stream<bool>> userOnlineStatus(String userId) async {
    return Stream.fromIterable(List.generate(10, (index) => index % 2 == 0));
  }

  // example return DateTime with positional optional argument
  Future<DateTime> getLastSignInTime([String? userID]) async {
    return DateTime.now();
  }

  // example return List of serializable object with both positional arg and optional arg 
  Future<List<Data>> getUsersData(List<String> userIDs, {bool includeAll = false}) async {
    return List.generate(10, (index) => Data(id: index, data: 'data')).toList();
  }
}

// sample Serializable Class
class Data {
  final int id;
  final String data;
  Data({
    required this.id,
    required this.data,
  });

  Map<String, dynamic> toMap() => throw UnimplementedError();
  String toJson() => throw UnimplementedError();
  factory Data.fromMap(Map<String, dynamic> map) => throw UnimplementedError();
  factory Data.fromJson(String jsonString) => throw UnimplementedError();
}

// sample expected output

// temp, this should be the response from shelf.
// mock
  // need importing shelf package => import 'package:shelf/shelf.dart'; 
class Response { 
  const Response();
  factory Response.ok(Object? body) => Response();
  factory Response.bad({Object? body}) => Response();
}

abstract class BaseHandler {
  /// the full route to the handler
  String get route;

  /// The request handler
  FutureOr<Response> handler(Map<String, dynamic> map); // need importing async =>  import 'dart:async';

  /// The HTTP verb
  // for now only post is used for all types of requests
  final String verb = 'POST';
}

class AppGetAppVersionHandler extends BaseHandler {
  final App app;

  AppGetAppVersionHandler(this.app);

  @override
  String get route => 'app/get_app_version';

  @override
  Response handler(Map<String, dynamic> map) {
    final body = app.getAppVersion();
    return Response.ok(body);
  }
}

class AppGetUserDataHandler extends BaseHandler {
  final App app;

  AppGetUserDataHandler(this.app);

  @override
  String get route => 'app/get_app_version';

  @override
  Response handler(Map<String, dynamic> map) {
    final userID = map['userID'];
    final body = app.getUserData(userID: userID);
    return Response.ok(body);
  }
}

