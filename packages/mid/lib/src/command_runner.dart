import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'package:mid/src/commands/generate.dart';

import 'commands/create.dart';
import '../version.dart';

class MIDCommandRunner extends CommandRunner<void> {
  MIDCommandRunner()
      : super(
          'mid',
          'mid - an API generation tool',
        ) {
    argParser.addFlag(
      'verbose',
      negatable: false,
      help: 'Enable verbose logging.',
    );
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the current mid version.',
    );

    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'the path to the working directory where the command should run',
      defaultsTo: Directory.current.path,
    );

    addCommand(GenerateCommand());
    addCommand(CreateCommand());
  }

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      // ignore: avoid_print
      print(midVersion);
      return;
    }

    final dir = p.normalize(p.absolute(topLevelResults['dir'] as String));
    if (dir != Directory.current.path) {
      if (!Directory(dir).existsSync()) {
        throw Exception('The given directory ($dir) does not exist');
      }
    }

    await super.runCommand(topLevelResults);
  }
}
