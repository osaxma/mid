import 'dart:async';
import 'dart:io';
import 'package:mid/src/templates/init.dart';
import 'package:path/path.dart' as p;
import 'package:mid/src/common/io_utils.dart';

import 'base.dart';

/// Creating a mid project
///
/// This will create new directory containing two dart projects such as:
///   <project_name>
///         |- <project_name>_client
///         |- <project_name>_server
///         |- other files...
class CreateCommand extends MIDCommand {
  CreateCommand() {
    argParser.addFlag(
      'force',
      negatable: false,
      help: 'Force project generation, even if the target directory already exists.',
    );
  }

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
    final targetDir = Directory(argResults!.rest.first).absolute;
    final dir = targetDir.path;
    if (targetDir.existsSync() && !argResults!['force']) {
      logger.stderr("Directory '$dir' already exists (use `--force` to force creation)");
      return;
    }

    String projectName = p.basename(dir);
    if (projectName == '.') {
      projectName = p.basename(Directory.current.path);
    }

    if (!targetDir.existsSync()) {
      targetDir.createSync();
    }

    final serverProjectDir = p.normalize(p.join(targetDir.path, '${projectName}_server'));
    var prog = logger.progress('building server project');
    await createServerProject(serverProjectDir);
    prog.finish();

    final clientProjectDir = p.normalize(p.join(targetDir.path, '${projectName}_client'));
    prog = logger.progress('building client project');
    await createClientProject(clientProjectDir);
    prog.finish();
    logger.stdout('done and dusted');
    return;
  }

  Future<void> createServerProject(String path) async {
    await createDartProject(path, force: true);
    // delete bin folder, content of lib and content of test
    clearDirContent(p.join(path, 'bin'));
    clearDirContent(p.join(path, 'lib'));
    clearDirContent(p.join(path, 'test'));
    await addPubDeps(path, ['shelf', 'shelf_router', 'http']);

    // create server default files
    createFileSync(p.join(path, 'bin', 'server.dart'), contents: binServerDotDart);
    createFileSync(p.join(path, 'mid', 'endpoints.dart'), contents: endpointsDotDart, recursive: true);
    createFileSync(p.join(path, 'mid', 'server.dart'), contents: serverDotDart);
    createFileSync(p.join(path, 'mid', 'middlewares.dart'), contents: middleWaresDotDart);
    createFileSync(p.join(path, 'mid', 'handlers.dart'), contents: handlersDotDart);
    createFileSync(p.join(path, 'mid', 'serializers.dart'), contents: '');
  }

  Future<void> createClientProject(String path) async {
    await createDartProject(path, force: true);
    // delete bin folder, content of lib and content of test
    clearDirContent(p.join(path, 'bin'));
    clearDirContent(p.join(path, 'lib'));
    clearDirContent(p.join(path, 'test'));
  }
}
