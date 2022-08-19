import 'dart:io';

import 'package:cli_util/cli_logging.dart';
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

  ClientLibGenerator({
    required this.serverProjectPath,
    required this.logger,
    required this.clientLibProjectPath,
  });

  /// Generates the client library
  ///
  /// Changes won't be commited until [commit] is invoked.
  Future<void> generate() async {
    final endpointsPath = getEndpointsPath(serverProjectPath);

    final routes = await parseRoutes(endpointsPath, logger);

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
    final routeClassName = src.classInfo.classNameForClient;
    fields.writeln('late final $fieldName = $routeClassName($args);');
  }
  final className = '${projectName.capitalizeFirst()}Client';

  return '''
import 'package:mid_client/mid_client.dart';
${importStatements.toString()}

class $className extends BaseClient {

  $fields
  
  $className({required String url,  required Map<String, String> Function() headersProvider}) 
    : super(url: url, headersProvider: headersProvider);
}
''';
}

class _ClientSource {
  final ClassInfo classInfo;
  final String source;

  String get fileName => '${classInfo.className.toSnakeCaseFromPascalCase()}.dart';

  _ClientSource(this.classInfo, this.source);
}
