import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/common/io_utils.dart';
import 'package:mid/src/common/types_collector.dart';
import 'package:mid/src/common/utils.dart';
import 'package:mid/src/common/models.dart';
import 'package:mid/src/generators/client_lib_generator/_source_generator.dart';
import 'package:mid/src/generators/client_lib_generator/serializer_client.dart';
import 'package:mid/src/templates/client_templates.dart';
import 'package:path/path.dart' as p;

/// Generates mid client library in the following structure:
///
///   |- lib
///       |- mid
///           |- routes
///                 |- route_1.dart
///                 |- route_2.dart
///           |- models
///                 |- models.dart (for now all in one file)
///           |- client.dart
///           |- models.dart (to export models)
///           |- routes.dart (to export routes)
///           |- interceptors.dart (to export interceptors types)
///       |- <project_name>_client.dart (exports client, models, routes, interceptors)
///
///
class ClientLibGenerator {
  /// The server project path
  final String serverProjectPath;

  /// The project where the client lib will be generated.
  final String clientLibProjectPath;
  final Logger logger;

  late final String models;
  final _clientSources = <ClientSource>[];
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
      _clientSources.add(ClientSource(route, source));
    }

    final types = getAllNonDartTypes(routes);

    models = ClientClassesSerializer(types: types).generate();
  }

  /// commit the generated code
  ///
  /// This will write the generated code into files.
  Future<void> commit() async {
    /* -------------------------------------------------------------------------- */
    /*                                CREATE ROUTES                               */
    /* -------------------------------------------------------------------------- */
    // deletes all routes for new ones to be generated
    // This is necessary since a route name may change or get deleted between runs
    clearDirContent(p.join(clientLibProjectPath, 'lib', 'mid', 'routes'));
    final routesFileNames = <String>[];
    for (final source in _clientSources) {
      final file = File(p.join(clientLibProjectPath, 'lib', 'mid', 'routes', source.fileName));
      _createOrOverwrite(file, source.source);
      routesFileNames.add(p.basename(file.path));
    }

    final routesExporter = File(p.join(clientLibProjectPath, 'lib', 'mid', 'routes.dart'));
    _createOrOverwrite(routesExporter, routesFileNames.map((n) => "export 'routes/$n';").join('\n'));
    /* -------------------------------------------------------------------------- */
    /*                                CREATE MODELS                               */
    /* -------------------------------------------------------------------------- */

    /// TODO: each model should be in its own file
    final modelsFile = File(p.join(clientLibProjectPath, 'lib', 'mid', 'models', 'models.dart'));
    _createOrOverwrite(modelsFile, models);

    // TODO: this should contains all models
    final modelExporter = File(p.join(clientLibProjectPath, 'lib', 'mid', 'models.dart'));
    _createOrOverwrite(modelExporter, "export 'models/models.dart';");
    /* -------------------------------------------------------------------------- */
    /*                                CREATE CLIENT                               */
    /* -------------------------------------------------------------------------- */

    final projectName = p.basename(p.dirname(clientLibProjectPath));
    final clientContents = generateClientFileContents(_clientSources, projectName);
    final clientFile = File(p.join(clientLibProjectPath, 'lib', 'mid', 'client.dart'));
    _createOrOverwrite(clientFile, clientContents);

    /* -------------------------------------------------------------------------- */
    /*                              CREATE EXPORTERS                              */
    /* -------------------------------------------------------------------------- */

    final clientExporterFile = File(p.join(clientLibProjectPath, 'lib', '${projectName}_client.dart'));
    _createOrOverwrite(clientExporterFile, clientLibraryFileContents);
    final interceptorsExporterFile = File(p.join(clientLibProjectPath, 'lib', 'interceptors.dart'));
    _createOrOverwrite(interceptorsExporterFile, clientInterceptorsDotDartContent);
  }
}

void _createOrOverwrite(File file, String contents) {
  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }
  file.writeAsStringSync(contents);
}
