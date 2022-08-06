import 'dart:async';
import 'dart:io';

import 'package:mid/src/templates/init.dart';
import 'package:path/path.dart' as p;
import 'package:mid/src/common/io_utils.dart';

import 'base.dart';

class InitCommand extends MIDCommand {
  InitCommand();

  @override
  final String name = 'init';

  @override
  final String description = 'initialize an existing project';

  @override
  FutureOr<void>? run() async {
    final path = Directory.current.path;

    if (!isDartProject(path)) {
      throw Exception(
          'This does not seem to be a dart project directory.\nMake sure to run the code in the root folder');
    }

    if (isMidProject(path)) {
      throw Exception('The project seem to be already initialized since there a `mid` folder already exists');
    }

    _createFileSync(p.join(path, 'mid', 'entrypoint.dart'), entryPointDotDart);
    _createFileSync(p.join(path, 'mid', 'server.dart'), serverDotDart);
    _createFileSync(p.join(path, 'mid', 'middlewares.dart'), middleWaresDotDart);
    _createFileSync(p.join(path, 'mid', 'handlers.dart'), handlersDotDart);
  }

  void _createFileSync(String path, [String? contents]) {
    final file = File(path);
    file.createSync(recursive: true);
    if (contents != null) {
      file.writeAsStringSync(contents);
    }
  }
}
