import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/generators/common.dart';
import 'package:path/path.dart' as p;

import '_source_generator.dart';

class EndPointsGenerator {
  final String serverProjectPath;
  final Logger logger;

  late final String _source;

  EndPointsGenerator({required this.serverProjectPath, required this.logger});

  Future<void> generate() async {
    final endpointsPath = getEndpointsPath(serverProjectPath);

    final routes = await parseRoutes(endpointsPath, logger);

    _source = EndPointsSourceGenerator(routes).generate();
  }

  Future<void> commit() async {
    final file = File(p.join(serverProjectPath, 'mid', 'handlers.dart'));
    file.writeAsStringSync(_source);
  }
}
