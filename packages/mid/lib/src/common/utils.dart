import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: unused_import
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
// ignore: implementation_imports
// import 'package:analyzer/src/dart/analysis/byte_store.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/file_byte_store.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:mid/src/common/models.dart';
import 'package:mid/src/common/visitors.dart';
import 'package:path/path.dart' as p;

/// Get Resolved Unit using [resolveFile2] function (slow)
Future<ResolvedUnitResult> getResolvedUnit1(String path) async {
  final resolvedFile = await resolveFile2(path: path);

  return resolvedFile as ResolvedUnitResult;
}

/// Get Resolved unit using [AnalysisContextCollectionImpl] (supposedly faster but involved)
///
//
// see discussion here: https://github.com/dart-lang/sdk/issues/46914
//
// notes:
// - It did not seem to help when running the command a second time
// - It's creating empty files :/
//
// TODO: figure out if this can be utilized to speed up resolving AST
//       especially if the command will run many times during development.
Future<ResolvedUnitResult> getResolvedUnit2(String filePath) async {
  // TODO: add `.analysis_cache` to `.gitignore` during init
  final cachePath = p.join(p.dirname(filePath), '.analysis_cache');

  // option 1:
  // ignore: unused_local_variable
  final evictingFBS = EvictingFileByteStore(
    cachePath,
    1024 * 1024, // 1MB
  );

  // option: 2
  final fbs = FileByteStore(cachePath);

  final analysisContext = AnalysisContextCollectionImpl(
      includedPaths: [filePath],
      byteStore: fbs,
      // fileContentCache: FileContentCache(),
      resourceProvider: PhysicalResourceProvider());

  final context = analysisContext.contextFor(filePath);

  final resolvedUnit = await context.currentSession.getResolvedUnit(filePath);

  return resolvedUnit as ResolvedUnitResult;
}

// TODO: move these to an extention on [DartType]

bool isDartCollection(DartType type) =>
    type.isDartCoreList || type.isDartCoreSet || type.isDartCoreMap || type.isDartCoreIterable;

bool isDartType(DartType type) {
  return isBasicType(type) ||
      isDuration(type) ||
      isDateTime(type) ||
      isDartCollection(type) ||
      isAsyncType(type) ||
      isOtherDartType(type) ||
      isEnum(type) ||
      isUri(type) ||
      isBigInt(type);
}

// do not use `type.isDartCoreEnum` since that represnt the class `Enum`
bool isEnum(DartType type) => type.element2 is EnumElement;

bool isUri(DartType type) =>
    type.getDisplayString(withNullability: false) == 'Uri' && isFromCoreLib(type as InterfaceType);

bool isBigInt(DartType type) =>
    type.getDisplayString(withNullability: false) == 'BigInt' && isFromCoreLib(type as InterfaceType);

bool isFromCoreLib(InterfaceType type) => getTypePackageURI(type) == 'dart:core';

bool isBasicType(DartType type) {
  return type.isDartCoreBool ||
      type.isDartCoreString ||
      type.isDartCoreDouble ||
      type.isDartCoreInt ||
      type.isDartCoreNum ||
      type.isDartCoreObject ||
      type.isDartCoreEnum ||
      type.isDynamic;
}

bool isTypeNullable(DartType type) => type.nullabilitySuffix != NullabilitySuffix.none;

bool isOtherDartType(DartType type) {
  return type.isVoid || type.isDartCoreFunction || type.isDartCoreSymbol || type.isDartCoreNull || type.isBottom;
}

bool isAsyncType(DartType type) => type.isDartAsyncStream || type.isDartAsyncFutureOr || type.isDartAsyncFuture;

bool isDuration(DartType type) => type.getDisplayString(withNullability: false) == 'Duration';
bool isDateTime(DartType type) => type.getDisplayString(withNullability: false) == 'DateTime';

bool isFutureVoid(DartType type) =>
    type is InterfaceType && type.isDartAsyncFuture && type.typeArguments.isNotEmpty && type.typeArguments.first.isVoid;

AstNode? getAstNodeFromElement(Element element) {
  final session = element.session;
  if (session == null) {
    return null;
  }
  final library = element.library;
  if (library == null) {
    return null;
  }
  final parsedLibResult = session.getParsedLibraryByElement(library);

  if (parsedLibResult is! ParsedLibraryResult) {
    return null;
  }
  final elDeclarationResult = parsedLibResult.getElementDeclaration(element);
  return elDeclarationResult?.node;
}

/// [Element] must be resolved
bool elementHasAnnotation(Element element, String annotation) {
  return element.metadata.any((element) {
    return element.element?.displayName == annotation;
  });
}

bool typeHasAnnotation(InterfaceType type, String annotation) {
  return type.element2.metadata.any((element) {
    return element.element?.displayName == annotation;
  });
}

String? getTypePackageURI(InterfaceType type) {
  return type.element2.librarySource.uri.toString();
}

String getEndpointsPath(String projectPath) {
  final path = p.join(projectPath, 'lib', 'mid', 'endpoints.dart');
  if (FileSystemEntity.isFileSync(path)) {
    return path;
  } else {
    throw Exception('the ${p.basename(path)} file does not exist at ${p.dirname(path)}');
  }
}

Future<List<ClassInfo>> parseRoutes(String endpointsPath, [Logger? logger]) async {
  final prog = logger?.progress('resolving AST (this will take few seconds)');
  // note: for some reason this is preventing the progress from displying the rotatting thingie '/ - / | '
  //       I tried  `await Future.delayed(Duration(seconds: 3));` and with that it worked.
  final resolvedFile = await getResolvedUnit1(endpointsPath);
  prog?.finish(message: '\nresolved AST in  ${prog.elapsed.inMilliseconds}-ms');

  final visitor = RoutesCollectorFromEndpointsFunction(filePath: endpointsPath);

  try {
    resolvedFile.unit.visitChildren(visitor);
  } catch (e) {
    logger?.stderr(e.toString());
    throw Exception('could not resolve $endpointsPath');
  }

  return visitor.routes;
}

bool hasFromMap(InterfaceType type) {
  return type.element2.getNamedConstructor('fromMap') != null || type.getMethod('fromMap')?.isStatic == true;
}

bool hasFromJson(InterfaceType type) {
  return type.element2.getNamedConstructor('fromJson') != null || type.getMethod('fromJson')?.isStatic == true;
}

bool hasToMap(InterfaceType type) {
  return type.getMethod('toMap') != null;
}

bool hasToJson(InterfaceType type) {
  return type.getMethod('toJson') != null;
}
