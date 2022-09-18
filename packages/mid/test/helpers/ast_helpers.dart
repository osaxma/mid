import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as p;

enum Samples {
  endpoints('endpoints.dart'),
  dataclass('data_class_sample.dart'),
  ;

  final String filename;
  const Samples(this.filename);

  Future<ResolvedUnitResult> getResolvedAST() => getResolvedSample(filename);
}

Future<ResolvedUnitResult> getResolvedSample(String name) async {
  // Directory.current.path always returns the root directory of the project
  final samplePath = p.join(Directory.current.path, 'test', 'samples', name);
  final resolvedFile = await resolveFile2(path: samplePath) as ResolvedUnitResult;
  return resolvedFile;
}

Future<LibraryElement> getResolvedASTfromString(String code) async {
  final filePath = '/it/does/not/matter/file.dart';
  final collection = AnalysisContextCollection(
    includedPaths: [filePath],
    resourceProvider: OverlayResourceProvider(
      PhysicalResourceProvider(),
    )..setOverlay(
        filePath,
        content: code,
        modificationStamp: 0,
      ),
  );

  final analysisSession = collection.contextFor(filePath).currentSession;

  final libraryElement = await analysisSession
      .getLibraryByUri('file://$filePath')
      .then((libraryResult) => (libraryResult as LibraryElementResult).element);

  return libraryElement;
}
