import 'dart:io';
import 'package:path/path.dart' as p;

int get terminalWidth {
  if (stdout.hasTerminal) {
    return stdout.terminalColumns;
  }

  return 80;
}

bool isDartProject(String path) {
  return FileSystemEntity.isFileSync(p.join(path, 'pubspec.yaml'));
}

bool isMidProject(String path) {
  return FileSystemEntity.isDirectorySync(p.join(path, 'mid'));
}

void clearDirContent(String path) {
  final testDir = Directory(path);
  final dirContents = testDir.listSync();
  for (var element in dirContents) {
    element.deleteSync(recursive: true);
  }
}

void replaceFileContent(String path, String content) {
  final file = File(path);
  file.writeAsStringSync(content, mode: FileMode.writeOnly);
}

void createFileSync(String path, {String? contents, bool recursive = false}) {
  final file = File(path);
  file.createSync(recursive: recursive);
  if (contents != null) {
    file.writeAsStringSync(contents);
  }
}

/// the [projectPath] should include the project directory name
Future<void> createDartProject(String projectPath, {bool force = false}) async {
  final args = ['create', projectPath, if (force) '--force'];
  final res = await Process.run(Platform.resolvedExecutable, args);

  if (res.exitCode != 0) {
    throw Exception('could not create project at $projectPath due to the following error:\n${res.stderr.toString()}');
  }
}

Future<void> addPubDeps(String projectPath, List<String> deps, {bool dev = false}) async {
  // note: this will fail if a dependency already exist with an error such:
  //      "<dep>" is already in "dependencies". Use "pub upgrade <dep>" to upgrade to a later version!
  final args = ['pub', 'add', ...deps, if (dev) '--dev'];

  final res = await Process.run(
    Platform.executable,
    args,
    workingDirectory: projectPath,
  );

  if (res.exitCode != 0) {
    throw Exception(
        'could not run `${args.reduce((p, e) => '$p $e')}` project at $projectPath due to the following error:\n${res.stderr.toString()}');
  }
}

String getServerProjectPathFromCurrentPath() {
  final currentDirPath = Directory.current.path;
  final currentDirName = p.basename(currentDirPath);

  // if within <project_name>_server/
  if (isMidProject(currentDirPath)) {
    return currentDirPath;
  }

  // if within <project_name>_client/
  if (currentDirName.endsWith('_client')) {
    final serverDirName = currentDirName.replaceFirst('_client', '_server');
    final serverDir = p.join(p.dirname(currentDirPath), serverDirName);
    if (isMidProject(serverDir)) {
      return serverDir;
    }
  }

  // if within <project_name>
  final dirElements = Directory.current.listSync().whereType<Directory>();
  for (var element in dirElements) {
    final path = element.path;
    if (path.endsWith('_server')) {
      if (isMidProject(path)) {
        return path;
      }
    }
  }

  throw Exception('could not find `mid` server project');
}

String getClientProjectPathFromCurrentPath() {
  final currentDirPath = Directory.current.path;
  final currentDirName = p.basename(currentDirPath);
  // if within <project_name>_client/
  if (currentDirName.endsWith('_client')) {
    return currentDirPath;
  }
  // if within <project_name>_server/
  if (currentDirName.endsWith('_server')) {
    final clientDirName = currentDirName.replaceFirst('_server', '_client');
    final clientDir = p.join(p.dirname(currentDirPath), clientDirName);
    if (Directory(clientDir).existsSync()) {
      return clientDir;
    }
  }

  // if within <project_name>
  final dirElements = Directory.current.listSync().whereType<Directory>();
  for (var element in dirElements) {
    final path = element.path;
    if (path.endsWith('_client')) {
      return path;
    }
  }

  throw Exception('could not find client project path');
}
