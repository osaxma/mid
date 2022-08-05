import 'dart:async';

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
    print('GenerateEndPointsCommand called');
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