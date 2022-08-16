import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/common/utils.dart';
import 'package:mid/src/generators/endpoints_generator/serializer_server.dart';
import 'package:path/path.dart' as p;

import '_source_generator.dart';

class EndPointsGenerator {
  final String serverProjectPath;
  final Logger logger;

  late final String _endpointsSource;
  late final String _serializersSource;

  EndPointsGenerator({required this.serverProjectPath, required this.logger});

  Future<void> generate() async {
    final endpointsPath = getEndpointsPath(serverProjectPath);

    final routes = await parseRoutes(endpointsPath, logger);

    _endpointsSource = EndPointsSourceGenerator(routes).generate();

    final types = getAllNonDartTypes(routes);

    _serializersSource = ServerClassesSerializer(types: types).generateCode();
  }

  Future<void> commit() async {
    final endpointsFile = File(p.join(serverProjectPath, 'mid', 'handlers.dart'));
    final serializersFile = File(p.join(serverProjectPath, 'mid', 'serializers.dart'));
    endpointsFile.writeAsStringSync(_endpointsSource);
    serializersFile.writeAsStringSync(_serializersSource);
  }
}
