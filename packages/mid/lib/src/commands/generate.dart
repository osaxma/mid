import 'dart:async';
import 'dart:io';

import 'package:mid/src/common/io_utils.dart';
import 'package:mid/src/generators/endpoints_generator/endpoints_generator.dart';

import 'base.dart';

class GenerateCommand extends MIDCommand {
  GenerateCommand() {
    addSubcommand(GenerateEndPointsCommand());
  }

  @override
  final String name = 'generate';

  @override
  final List<String> aliases = ['g'];

  @override
  final String description = 'code generator (see subcommands by running --help on the command)';

  @override
  FutureOr<void>? run() async {
    print('GenerateCommand called');
  }
}

class GenerateEndPointsCommand extends MIDCommand {
  GenerateEndPointsCommand() {/*  */}

  @override
  final String name = 'endpoints';

  @override
  final List<String> aliases = ['e'];

  @override
  final String description = 'generates api endpoints';

  @override
  FutureOr<void>? run() async {
    final path = Directory.current.path;

    if (!isMidProject(path)) {
      throw Exception('''
  Could not find `mid` directory. 
    - Make sure you ran `mid init`.
    - If yes, then make sure you are in the root directory of the dart project.
''');
    }

    final generator = EndPointsGenerator(
      projectPath: path,
      logger: logger,
    );

    await generator.generate();
  }
}

class GenerateClientLibCommand extends MIDCommand {
  GenerateClientLibCommand() {/*  */}

  @override
  final String name = 'client';

  @override
  final List<String> aliases = ['c'];

  @override
  final String description = 'generates client library';

  @override
  FutureOr<void>? run() async {
    print('GenerateEndPointsCommand called');
  }
}
