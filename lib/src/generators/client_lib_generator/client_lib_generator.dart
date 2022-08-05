import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/generators/client_lib_generator/_visitors.dart';
import 'package:path/path.dart' as p;

class ClientLibGenerator {
  final Logger logger;

  ClientLibGenerator(this.logger);

  void generate(String projectPath) async {
    final path = p.join(projectPath, 'mid', 'entrypoint.dart');

    final s = Stopwatch()..start();
    final resolvedFile = await resolveFile2(path: path);

    s.stop();
    logger.trace('file resolved in ${s.elapsedMilliseconds}-ms \n');

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
