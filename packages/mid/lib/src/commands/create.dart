import 'dart:async';
import 'dart:io';
import 'package:mid/src/templates/create.dart';
import 'package:path/path.dart' as p;
import 'package:mid/src/common/io_utils.dart';

import 'base.dart';

/// Creating a mid project
///
/// This will create new directory containing two dart projects such as:
///   <project_name>
///         |- <project_name>_client
///                 |- lib
///                     |- models
///                          |- model1.dart
///                          |- model2.dart
///                     |- routes
///                          |- route1.dart
///                          |- route2.dart
///                 |- models.dart
///                 |- client.dart
///         |- <project_name>_server
///                 |- bin
///                     |- server.dart
///                 |- lib/mid/
///                         |- generated
///                             |- handlers.dart
///                             |- serializers.dart
///                             |- server.dart
///                         |- endpoints.dart
///                         |- middlewares.dart
///         |- other files...
class CreateCommand extends MIDCommand {
  CreateCommand(this.workingDirectoryPath) {
    argParser.addFlag(
      'force',
      negatable: false,
      help: 'Force project generation, even if the target directory already exists.',
    );
  }

  final String workingDirectoryPath;

  @override
  final String name = 'create';

  @override
  final String description = 'creates a new mid project';

  @override
  String get invocation => '${super.invocation} <directory>';

  @override
  FutureOr<void>? run() async {
    if (argResults!.rest.isEmpty) {
      logger.stdout('No targert <directory> was provided');
      printUsage();
      return;
    }

    // TODO: should thsi be relative to `workingDirectoryPath`
    final targetDir = Directory(argResults!.rest.first).absolute;
    final dir = targetDir.path;
    if (targetDir.existsSync() && !argResults!['force']) {
      logger.stderr("Directory '$dir' already exists (use `--force` to force creation)");
      return;
    }

    String projectName = p.basename(dir);
    if (projectName == '.') {
      projectName = p.basename(workingDirectoryPath);
    }

    if (!targetDir.existsSync()) {
      targetDir.createSync();
    }

    final serverProjectDir = p.normalize(p.join(targetDir.path, '${projectName}_server'));
    var prog = logger.progress('building server project');
    await createServerProject(serverProjectDir, projectName);
    prog.finish();

    final clientProjectDir = p.normalize(p.join(targetDir.path, '${projectName}_client'));
    prog = logger.progress('building client project');
    await createClientProject(clientProjectDir);
    prog.finish();
    logger.stdout('done and dusted');
    return;
  }

  Future<void> createServerProject(String path, String projectName) async {
    await createDartProject(path, force: true);
    // delete bin folder, content of lib and content of test
    clearDirContent(p.join(path, 'bin'));
    clearDirContent(p.join(path, 'lib'));
    clearDirContent(p.join(path, 'test'));
    await addPubDeps(path, ['shelf', 'shelf_router', 'mid', 'mid_server', 'mid_protocol', 'collection']);

    // create server default files
    createFileSync(p.join(path, 'bin', 'server.dart'), contents: getServerDotDartContent(projectName));
    createFileSync(p.join(path, 'lib/mid/', 'endpoints.dart'), contents: endpointsDotDart, recursive: true);
    createFileSync(p.join(path, 'lib/mid/', 'middlewares.dart'), contents: middleWaresDotDart);
    createFileSync(p.join(path, 'lib/mid/generated/', 'handlers.dart'), contents: handlersDotDart, recursive: true);
    createFileSync(p.join(path, 'lib/mid/generated/', 'serializers.dart'), contents: '');
    // TODO: add Dockerfile & .dockerignore (or use --template=server-shelf when creating dart project)
  }

  Future<void> createClientProject(String path) async {
    await createDartProject(path, force: true);
    // delete bin folder, content of lib and content of test
    clearDirContent(p.join(path, 'bin'));
    clearDirContent(p.join(path, 'lib'));
    clearDirContent(p.join(path, 'test'));

    await addPubDeps(path, ['http', 'collection', 'mid', 'mid_protocol', 'mid_client']);
  }
}
