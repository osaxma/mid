import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/common/types_collector.dart';
import 'package:mid/src/common/utils.dart';
import 'package:mid/src/common/models.dart';
import 'package:mid/src/generators/client_lib_generator/_source_generator.dart';
import 'package:mid/src/generators/client_lib_generator/serializer_client.dart';
import 'package:path/path.dart' as p;
import 'package:mid/src/common/extensions.dart';

/// Process taken by the generator:
///
/// - generate the client library if it does not exist
/// - add common files at lib/src/common (overwrite to ensure uptodate)
/// - create a file for each base route at lib/src/routes
/// - add export statement at the lib/client.dart or lib/routes.dart or lib/api.dart
class ClientLibGenerator {
  /// The server project path
  final String serverProjectPath;

  /// The project where the client lib will be generated.
  final String clientLibProjectPath;
  final Logger logger;

  late final String _dataClasses;
  final _clientSources = <_ClientSource>[];
  final List<ClassInfo>? routes;

  ClientLibGenerator({
    required this.serverProjectPath,
    required this.logger,
    required this.clientLibProjectPath,
    this.routes,
  });

  /// Generates the client library
  ///
  /// Changes won't be commited until [commit] is invoked.
  Future<void> generate() async {
    final endpointsPath = getEndpointsPath(serverProjectPath);

    final routes = this.routes ?? await parseRoutes(endpointsPath, logger);

    for (final route in routes) {
      final generator = ClientEndPointGenerator(route);
      final source = generator.generate();
      _clientSources.add(_ClientSource(route, source));
    }

    final types = getAllNonDartTypes(routes);

    _dataClasses = ClientClassesSerializer(types: types).generate();
  }

  /// commit the generated code
  ///
  /// This will write the generated code into files.
  Future<void> commit() async {
    for (final source in _clientSources) {
      final file = File(p.join(clientLibProjectPath, 'lib', 'routes', source.fileName));
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      file.writeAsStringSync(source.source);
    }

    final file = File(p.join(clientLibProjectPath, 'lib', 'models.dart'));
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(_dataClasses);

    final projectName = p.basename(p.dirname(clientLibProjectPath));
    final clientDotDart = _generateClientDotDart(_clientSources, projectName);
    final clientDotDartFile = File(p.join(clientLibProjectPath, 'lib', 'client.dart'));

    if (!clientDotDartFile.existsSync()) {
      clientDotDartFile.createSync(recursive: true);
    }
    clientDotDartFile.writeAsStringSync(clientDotDart);
  }
}

String _generateClientDotDart(List<_ClientSource> sources, String projectName) {
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
import 'package:mid_protocol/mid_protocol.dart';
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

class _ClientSource {
  final ClassInfo classInfo;
  final String source;

  String get fileName => '${classInfo.className.toSnakeCaseFromPascalCase()}.dart';

  _ClientSource(this.classInfo, this.source);
}
