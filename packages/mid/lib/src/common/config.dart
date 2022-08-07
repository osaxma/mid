import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

Config getConfig(String projectPath) {
  final path = p.join(projectPath, 'mid', 'config.jsonc');
  final configJSON = File(path).readAsStringSync();
  final data = json.decode(_removeComments(configJSON)) as Map<String, dynamic>;
  return Config.fromConfigFile(data);
}

class Config {
  final ClientConfig clientConfig;
  final ServerConfig serverConfig;

  Config(this.clientConfig, this.serverConfig);

  factory Config.fromConfigFile(Map<String, dynamic> map) {
    return Config(
      ClientConfig(
        map['client']['target_directory'],
        map['client']['project_name'],
      ),
      ServerConfig(),
    );
  }
}

class ClientConfig {
  final String targetDirectory;
  final String projectName;

  ClientConfig(this.targetDirectory, this.projectName);
}

class ServerConfig {}

// credit: https://stackoverflow.com/a/69168715/10976714
var commentRE = RegExp(r'"(?:[^\\"]|\\[^])*"|/\*[^]*?\*/|//.*');
String _removeComments(String jsonWithComments) => jsonWithComments.replaceAllMapped(commentRE, (m) {
      var s = m[0]!;
      return s.startsWith('"') ? s : "";
    });
