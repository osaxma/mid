import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/generators/endpoints_generator/endpoints_generator.dart';

void main() async {
  final gen = EndPointsGenerator(
    serverProjectPath: '/Users/osaxma/Projects/mid/examples/simple/backend/',
    logger: Logger.standard(),
  );

  await gen.generate();
}
