import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/common/analyzer.dart';
import 'package:mid/src/generators/endpoints_generator/_models.dart';
import 'package:mid/src/generators/endpoints_generator/_visitors.dart';
import 'package:path/path.dart' as p;

import '_source_generator.dart';

class EndPointsGenerator {
  final String projectPath;
  final Logger logger;

  EndPointsGenerator({required this.projectPath, required this.logger});

  Future<void> generate() async {
    final entryPointPath = _getEntryPointPath(projectPath);

    final routes = await _parseRoutes(entryPointPath);
    // routes.forEach((element) {
    //   element.getRoutes().forEach(print);
    // });

    final source = EndPointsSourceGenerator(routes).generate();

    final file = File(p.join(projectPath, 'mid', 'handlers.dart'));
    file.writeAsStringSync(source);
  }

  Future<List<ClassInfo>> _parseRoutes(String entryPointPath) async {
    final prog = logger.progress('resolving AST (this will take few seconds)');
    // note: for some reason this is preventing the progress from displying the rotatting thingie '/ - / | '
    //       I tried  `await Future.delayed(Duration(seconds: 3));` and with that it worked.
    final resolvedFile = await getResolvedUnit1(entryPointPath);
    prog.finish(message: '\nresolved AST in  ${prog.elapsed.inMilliseconds}-ms');

    final visitor = VisitEndPointsFunction(filePath: entryPointPath);

    try {
      resolvedFile.unit.visitChildren(visitor);
    } catch (e) {
      logger.stderr(e.toString());
      throw Exception('could not resolve $entryPointPath');
    }

    return visitor.routes;
  }

  String _getEntryPointPath(String projectPath) {
    final path = p.join(projectPath, 'mid', 'entrypoint.dart');
    if (FileSystemEntity.isFileSync(path)) {
      return path;
    } else {
      throw Exception('the ${p.basename(path)} file does not exist at ${p.dirname(path)}');
    }
  }
}
