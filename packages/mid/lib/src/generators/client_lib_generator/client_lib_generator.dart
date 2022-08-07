import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/generators/common.dart';

class ClientLibGenerator {
  final String projectPath;
  final Logger logger;

  ClientLibGenerator({
    required this.projectPath,
    required this.logger,
  });

  Future<void> generate() async {
    final entryPointPath = getEntryPointPath(projectPath);
    
    final routes = await parseRoutes(entryPointPath, logger);
  }
}
