import 'dart:async';
import 'dart:io';

import 'package:mid/src/common/io_utils.dart';
import 'package:mid/src/generators/client_lib_generator/client_lib_generator.dart';
import 'package:mid/src/generators/endpoints_generator/endpoints_generator.dart';

import 'base.dart';

// TODO(@osaxma): add `commit()` for all generators that is called after generation is successful
//                currently if an exception is thrown or an error occured between generation,
//                some files would be half written and such.
//
//                this will also allow using `--dry-run` for commands.

class GenerateCommand extends MIDCommand {
  GenerateCommand(this.workingDirectoryPath) {
    // TODO: combine into one tht generates both endpoints and client.
    addSubcommand(GenerateEndPointsCommand(workingDirectoryPath));
    addSubcommand(GenerateClientLibCommand(workingDirectoryPath));
  }

  final String workingDirectoryPath;

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
  GenerateEndPointsCommand(this.workingDirectoryPath) {/*  */}

  final String workingDirectoryPath;

  @override
  final String name = 'endpoints';

  @override
  final List<String> aliases = ['e'];

  @override
  final String description = 'generates api endpoints';

  @override
  FutureOr<void>? run() async {
    final path = getServerProjectPath(workingDirectoryPath);
    final generator = EndPointsGenerator(
      serverProjectPath: path,
      logger: logger,
    );

    await generator.generate();
    await generator.commit();
  }
}

class GenerateClientLibCommand extends MIDCommand {
  GenerateClientLibCommand(this.workingDirectoryPath);

  final String workingDirectoryPath;

  @override
  final String name = 'client';

  @override
  final List<String> aliases = ['c'];

  @override
  final String description = 'generates client library';

  @override
  FutureOr<void>? run() async {
    final serverProjectPath = getServerProjectPath(workingDirectoryPath);
    final clientLibraryPath = getClientProjectPath(workingDirectoryPath);

    final generator = ClientLibGenerator(
      serverProjectPath: serverProjectPath,
      clientLibProjectPath: clientLibraryPath,
      logger: logger,
    );

    await generator.generate();
    await generator.commit();
  }
}
