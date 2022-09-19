import 'dart:async';

import 'package:mid/src/common/io_utils.dart';
import 'package:mid/src/common/utils.dart';
import 'package:mid/src/generators/client_lib_generator/client_lib_generator.dart';
import 'package:mid/src/generators/server_lib_generator/server_lib_generator.dart';

import 'base.dart';

// TODO(@osaxma): add `commit()` for all generators that is called after generation is successful
//                currently if an exception is thrown or an error occured between generation,
//                some files would be half written and such.
//
//                this will also allow using `--dry-run` for commands.

class GenerateCommand extends MIDCommand {
  GenerateCommand() {
    // TODO: combine into one tht generates both endpoints and client.
    addSubcommand(GenerateEndPointsCommand());
    addSubcommand(GenerateClientLibCommand());
    addSubcommand(GenerateAllCommand());
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
  final String name = 'server';

  @override
  final List<String> aliases = ['s'];

  @override
  final String description = 'generates server library';

  @override
  FutureOr<void>? run() async {
    final path = getServerProjectPath(workingDirectoryPath);
    final generator = ServerLibGenerator(
      serverProjectPath: path,
      logger: logger,
    );

    await generator.generate();
    await generator.commit();
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

class GenerateAllCommand extends MIDCommand {
  GenerateAllCommand();

  @override
  final String name = 'all';

  @override
  final String description = 'generates both server and client libraries';

  @override
  FutureOr<void>? run() async {
    final serverProjectPath = getServerProjectPath(workingDirectoryPath);
    final clientLibraryPath = getClientProjectPath(workingDirectoryPath);

    final endpointsPath = getEndpointsPath(serverProjectPath);
    final routes = await parseRoutes(endpointsPath, logger);

    final clientGenerator = ClientLibGenerator(
      serverProjectPath: serverProjectPath,
      clientLibProjectPath: clientLibraryPath,
      logger: logger,
      routes: routes,
    );

    final serverGenerator = ServerLibGenerator(
      serverProjectPath: serverProjectPath,
      logger: logger,
      routes: routes,
    );

    await serverGenerator.generate();
    await clientGenerator.generate();

    await serverGenerator.commit();
    await clientGenerator.commit();
  }
}

