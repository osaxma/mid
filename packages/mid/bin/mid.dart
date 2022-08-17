import 'dart:io';

import 'package:mid/src/command_runner.dart';

void main(List<String> arguments) async {
  // TODO: move the try/catch inside the command runner and use the logger to print errors
  try {
    await MIDCommandRunner(Directory.current.path).run(arguments);
  } catch (err, s) {
    stderr.writeln(err);
    if (arguments.contains('--verbose')) {
      stderr.writeln(s);
    }
    exitCode = 1;
  }
  exit(exitCode);
}
