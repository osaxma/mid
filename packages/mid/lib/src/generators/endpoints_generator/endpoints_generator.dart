import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/generators/endpoints_generator/_visitors.dart';
import 'package:path/path.dart' as p;

class EndPointsGenerator {
  final String projectPath;
  final Logger logger;

  EndPointsGenerator({required this.projectPath, required this.logger});

  Future<void> generate() async {
    final path = p.join(projectPath, 'mid', 'entrypoint.dart');


    final prog = logger.progress('resolving AST (this will take few seconds)');
    final resolvedFile = await resolveFile2(path: path);
    prog.finish(message: '\nresolved AST in  ${prog.elapsed.inMilliseconds}-ms');
    
    final visitor = VisitEndPointsFunction(filePath: path);
    if (resolvedFile is ResolvedUnitResult) {
      try {
        resolvedFile.unit.visitChildren(visitor);
      } catch (e) {
        print(e);
        logger.stderr(e.toString());
      }
    }

    visitor.routes.forEach((element) {
      element.getRoutes().forEach(print);
    });
  }
}
