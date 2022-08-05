import 'dart:async';

import 'base.dart';

class InitCommand extends MIDCommand {
  InitCommand();

  @override
  final String name = 'init';

  @override
  final String description = 'initialize an existing project';

  @override
  FutureOr<void>? run() async {
    
    // creates a mid folder containing:
    // - mid.dart -- the server
    // - entrypoint.dart -- the entry point
    // - 
  }
}