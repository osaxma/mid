import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/generators/client_lib_generator/_source_generator.dart';
import 'package:mid/src/generators/client_lib_generator/client_lib_generator.dart';
import 'package:mid/src/generators/endpoints_generator/endpoints_generator.dart';

void main() async {
  final gen = ClientLibGenerator(
    serverProjectPath: '/Users/osaxma/Projects/mid/examples/simple/backend/',
    clientLibProjectPath: '/Users/osaxma/Projects/mid/examples/simple/client/',
    logger: Logger.standard(),
  );

  await gen.generate();
}
