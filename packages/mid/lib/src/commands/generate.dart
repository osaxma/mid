import 'dart:async';
import 'dart:io';

import 'package:mid/src/common/config.dart';
import 'package:mid/src/common/io_utils.dart';
import 'package:mid/src/generators/client_lib_generator/client_lib_generator.dart';
import 'package:mid/src/generators/endpoints_generator/endpoints_generator.dart';

import 'package:path/path.dart' as p;

import 'base.dart';

class GenerateCommand extends MIDCommand {
  GenerateCommand() {
    // TODO: combine into one tht generates both endpoints and client.
    addSubcommand(GenerateEndPointsCommand());
    addSubcommand(GenerateClientLibCommand());
  }

  @override
  final String name = 'generate';

  @override
  final List<String> aliases = ['g'];

  @override
  final String description = 'code generator (see subcommands by running --help on the command)';

  @override
  FutureOr<void>? run() async {}
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
    final path = getServerProjectPathFromCurrentPath();
    final generator = EndPointsGenerator(
      serverProjectPath: path,
      logger: logger,
    );

    await generator.generate();
  }
}

class GenerateClientLibCommand extends MIDCommand {
  GenerateClientLibCommand();

  @override
  final String name = 'client';

  @override
  final List<String> aliases = ['c'];

  @override
  final String description = 'generates client library';

  @override
  FutureOr<void>? run() async {
    final serverProjectPath = getServerProjectPathFromCurrentPath();
    final clientLibraryPath = getClientProjectPathFromCurrentPath();

    final generator = ClientLibGenerator(
      serverProjectPath: serverProjectPath,
      clientLibProjectPath: clientLibraryPath,
      logger: logger,
    );

    await generator.generate();
  }
}
