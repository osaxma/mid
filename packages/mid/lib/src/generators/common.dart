import 'dart:io';
import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/common/analyzer.dart';
import 'package:path/path.dart' as p;

import 'endpoints_generator/_models.dart';
import 'endpoints_generator/_visitors.dart';

String getEntryPointPath(String projectPath) {
  final path = p.join(projectPath, 'mid', 'entrypoint.dart');
  if (FileSystemEntity.isFileSync(path)) {
    return path;
  } else {
    throw Exception('the ${p.basename(path)} file does not exist at ${p.dirname(path)}');
  }
}

Future<List<ClassInfo>> parseRoutes(String entryPointPath, [Logger? logger]) async {
  final prog = logger?.progress('resolving AST (this will take few seconds)');
  // note: for some reason this is preventing the progress from displying the rotatting thingie '/ - / | '
  //       I tried  `await Future.delayed(Duration(seconds: 3));` and with that it worked.
  final resolvedFile = await getResolvedUnit1(entryPointPath);
  prog?.finish(message: '\nresolved AST in  ${prog.elapsed.inMilliseconds}-ms');

  final visitor = VisitEntryPointFunction(filePath: entryPointPath);

  try {
    resolvedFile.unit.visitChildren(visitor);
  } catch (e) {
    logger?.stderr(e.toString());
    throw Exception('could not resolve $entryPointPath');
  }

  return visitor.routes;
}
