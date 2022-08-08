import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/common/io_utils.dart';
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
  final String projectPath;
  final Logger logger;

  /// The project where the client lib will be generated.
  final String clientLibProjectPath;

  ClientLibGenerator({
    required this.projectPath,
    required this.logger,
    required this.clientLibProjectPath,
  });

  Future<void> generate() async {
    await _createClientLibProjectIfItDoesNotExist();

    final entryPointPath = getEntryPointPath(projectPath);

    final routes = await parseRoutes(entryPointPath, logger);

    // each route will be its own file
  }

  Future<void> _createClientLibProjectIfItDoesNotExist() async {
    if (isDartProject(clientLibProjectPath)) {
      return;
    }

    final dir = Directory(clientLibProjectPath);
    if (dir.existsSync()) {
      throw Exception('a directory already exists at $clientLibProjectPath but it is not a dart project');
    }

    final prog = logger.progress('creating dart project at $clientLibProjectPath ');
    await createDartProject(clientLibProjectPath);

    // delete bin folder, content of lib and content of test
    clearDirContent(p.join(clientLibProjectPath, 'bin'));
    clearDirContent(p.join(clientLibProjectPath, 'lib'));
    clearDirContent(p.join(clientLibProjectPath, 'test'));

    prog.finish(message: '\n');
    

    // TODO: put meaningful content in README.md and also upddate project in formation in `pubspec.yaml`
  }
}
