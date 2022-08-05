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