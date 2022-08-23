import 'package:mid/src/common/extensions.dart';
import 'package:mid/src/common/models.dart';

const clientInterceptorsDotDartContent = ''' 
export 'package:mid_protocol/mid_protocol.dart' show Message, MessageType, MessageInterceptor;
export 'package:mid_client/mid_client.dart' show Interceptor; 
export 'package:http/http.dart' show Request, Response;
''';

const clientLibraryFileContents = '''// Exporting client and data models
export 'mid/client.dart';
export 'mid/models.dart';
''';

// TODO: create a common source holder 
// this is temp for quickly moving on. 
class ClientSource {
  final ClassInfo classInfo;
  final String source;

  String get fileName => '${classInfo.className.toSnakeCaseFromPascalCase()}.dart';

  ClientSource(this.classInfo, this.source);
}

String generateClientFileContents(List<ClientSource> sources, String projectName) {
  final importStatements = StringBuffer();
  final fields = StringBuffer();
  for (final src in sources) {
    importStatements.writeln("import 'routes/${src.fileName}';");
    final args = 'executeHttp, executeStream';
    final fieldName = src.classInfo.className.toLowerCase();
    final routeClassName = src.classInfo.routeNameForClient;
    fields.writeln('late final $fieldName = $routeClassName($args);');
  }
  final className = '${projectName.toPascalCaseFromSnakeCase()}Client';

  return '''
import 'package:mid_client/mid_client.dart';
${importStatements.toString()}

/// A wrapper client for the http and websocket clients of a mid project
class $className extends BaseClient {

  $fields

  /// A wrapper client for the http and websocket clients of a mid project
  ///
  /// [url] is the server url. The client will parse the uri for both http and websocket.
  ///
  /// [initialHeaders] that will be used for sending http requests and establishing the
  /// websocket connection. The headers can be updated by invoking [updateHeaders] at any
  /// time. Alternatively, the headers for http requests can be modified by intercepting
  /// the requests (does not apply for websocket connection -- see [updateHeaders])
  ///
  /// [interceptors] a List of Interceptors that intercept http requests and responses
  ///
  /// Each [Interceptor.onRequest] is invoked before sending the request.
  /// And each [Interceptor.onResponse] is invoked before returning a response.
  ///
  /// The [interceptors] are invoked based on their order in the list starting from index 0.
  ///
  /// Important Notes:
  /// - Avoid changing ['content-type'] header as it'll be overwritten by the client.
  ///   For now, all requests will have "'content-type': 'application/json'".
  /// - All requests are sent using `http.post` at the time being.
  /// - The [interceptors] are not invoked on endpoints with a [Stream] retruen type
  ///   - see [updateHeaders] for more info.
  ///
  /// [messageInterceptors] -- a list of interceptors to intercept messages between
  /// the server and the client of the websocket connection.
  $className({
    required super.url,
    super.initialHeaders,
    super.interceptors,
    super.messageInterceptors,
  });
}
''';
}
