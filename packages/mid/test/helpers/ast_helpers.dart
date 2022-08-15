import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

Future<CompilationUnit> getResolvedSample(String name) async {
  // Directory.current.path always returns the root directory of the project
  final samplePath = p.join(Directory.current.path, 'test', 'samples', name);
  final resolvedFile = await resolveFile2(path: samplePath) as ResolvedUnitResult;
  return resolvedFile.unit;
}
