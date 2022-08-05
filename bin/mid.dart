import 'dart:io';

import 'package:mid/src/command_runner.dart';

void main(List<String> arguments) async {
  try {
    await MIDCommandRunner().run(arguments);
  } catch (err) {
    stderr.writeln(err.toString());
    exitCode = 1;
  }
  exit(exitCode);
}
