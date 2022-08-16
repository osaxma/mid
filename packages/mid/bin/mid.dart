import 'dart:io';

import 'package:mid/src/command_runner.dart';

void main(List<String> arguments) async {
  try {
    await MIDCommandRunner().run(arguments);
  } catch (err, s) {
    stderr.writeln(err);
    if (arguments.contains('--verbose')) {
      stderr.writeln(s);
    }
    exitCode = 1;
  }
  exit(exitCode);
}
