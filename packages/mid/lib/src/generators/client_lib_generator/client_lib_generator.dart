import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/common/io_utils.dart';
import 'package:mid/src/generators/client_lib_generator/_source_generator.dart';
import 'package:mid/src/generators/common.dart';
import 'package:path/path.dart' as p;

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

  ClientLibGenerator({
    required this.serverProjectPath,
    required this.logger,
    required this.clientLibProjectPath,
  });

  Future<void> generate() async {
    final entryPointPath = getEntryPointPath(serverProjectPath);

    final routes = await parseRoutes(entryPointPath, logger);

    final generator = ClientEndPointGenerator(routes.first);

    await generator.generate();

    // each route will be its own file
  }
}
