import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/generators/common.dart';
import 'package:path/path.dart' as p;

import '_source_generator.dart';

class EndPointsGenerator {
  final String projectPath;
  final Logger logger;

  EndPointsGenerator({required this.projectPath, required this.logger});

  Future<void> generate() async {
    final entryPointPath = getEntryPointPath(projectPath);

    final routes = await parseRoutes(entryPointPath, logger);

    final source = EndPointsSourceGenerator(routes).generate();

    final file = File(p.join(projectPath, 'mid', 'handlers.dart'));
    file.writeAsStringSync(source);
  }
}
