import 'dart:async';

// import 'package:path/path.dart' as p;
import 'package:mid/src/common/io_utils.dart';

import 'base.dart';

class DebugCommand extends MIDCommand {
  DebugCommand();

  @override
  final String name = 'debug';

  @override
  final String description = 'debug command (for internal use only) ';

  @override
  bool get hidden => true;
  

  @override
  FutureOr<void>? run() async {
    print(getClientProjectPathFromCurrentPath());
    print(getServerProjectPathFromCurrentPath());
  }
}