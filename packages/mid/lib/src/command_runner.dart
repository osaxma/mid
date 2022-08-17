import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mid/src/commands/generate.dart';

import 'commands/create.dart';
import 'commands/debug.dart';
import 'version.dart';

class MIDCommandRunner extends CommandRunner<void> {
  // TODO
  final String workingDirectoryPath;

  MIDCommandRunner(this.workingDirectoryPath)
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
      help: 'Print the current Melos version.',
    );

    addCommand(GenerateCommand(workingDirectoryPath));
    addCommand(CreateCommand(workingDirectoryPath));
    addCommand(DebugCommand(workingDirectoryPath));
  }

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      // ignore: avoid_print
      print(midVersion);
      return;
    }
    await super.runCommand(topLevelResults);
  }
}
