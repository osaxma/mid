import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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
  return isDartCollection(type) || isBasicType(type) || isDuration(type) || isDateTime(type);
}

bool isBasicType(DartType type) {
  return type.isDartAsyncFuture ||
      type.isDartAsyncFutureOr ||
      type.isDartAsyncStream ||
      type.isDartCoreBool ||
      type.isDartCoreDouble ||
      type.isDartCoreEnum ||
      type.isDartCoreInt ||
      type.isDartCoreNum ||
      type.isDartCoreObject ||
      type.isDartCoreString ||
      type.isDynamic ||
      // for the purpose of this project, these shouldn't be there (i.e. return type, method argument or class member)
      // type.isDartCoreFunction ||
      // type.isDartCoreSymbol ||
      // type.isDartCoreNull ||
      // type.isBottom ||
      type.isVoid;
}

bool isDuration(DartType type) => type.getDisplayString(withNullability: false) == 'Duration';
bool isDateTime(DartType type) => type.getDisplayString(withNullability: false) == 'DateTime';

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

/// see docs at [findAllNonDartTypesFromMethodElement]
Set<InterfaceType> getAllNonDartTypes(List<ClassInfo> classInfos) {
  final types = <InterfaceType>{};
  for (final classInfo in classInfos) {
    for (final m in classInfo.methodInfos) {
      types.addAll(findAllNonDartTypesFromMethodElement(m.methodElement));
    }
  }
  return types;
}

/// Collects the non-dart types from the method's return type and arguments recursively
///
/// For instance, given the following method:
/// ```dart
/// Session updateSession(User user, [String clientID]) {/* ... */}
/// ```
///
/// The method returns the following set: Session, User, and any other non-Dart type withihn them.
///
/// For instance, if `User` is defined as follows:
/// ```dart
/// class User {
///     final int id;
///     final String name;
///     final UserData data;
/// }
/// ```
/// and `UserData` is defined as follow:
/// ```dart
/// class UserData {
///   final String country;
///   final String language;
///   final MetaData metadata;
/// }
/// ```
///
/// The method returns the following set: {Session, User, UserData, MetaData}
///
/// and so on.
///
/// This method is mainly used to generate client side types as well as the server
/// serialization of these types.
Set<InterfaceType> findAllNonDartTypesFromMethodElement(MethodElement method) {
  final types = <InterfaceType>{};

  collectNonDartTypesFromType(method.returnType, types);
  for (final para in method.parameters) {
    collectNonDartTypesFromType(para.type, types);
  }

  final nonDartTypes = <InterfaceType>{};
  for (final t in types) {
    nonDartTypes.addAll(findAllNonDartTypesInTypeMembers(t));
  }
  // we can't add directly to the `types` while iteratting (e.g. Concurrent modification during iteration exception)
  types.addAll(nonDartTypes);

  return types;
}

/// Collects non-Dart types within a type recursively, if any.
///
/// For instance, if the given [type] is as follows:
/// ```dart
/// class User {
///     final int id;
///     final String name;
///     final UserData data;
/// }
/// ```
/// where `UserData` is defined as follow:
/// ```dart
/// class UserData {
///   final String country;
///   final String language;
///   final MetaData metadata;
/// }
/// ```
/// The method returns the following set: {UserData, MetaData}
///
/// If the given type does not contain any non-Dart types, then it'll return that type only.
///
/// Don't supply [visitedTypes] as it's used internally by the function itself.
Set<InterfaceType> findAllNonDartTypesInTypeMembers(InterfaceType type, [Set<InterfaceType>? visitedTypes]) {
  final set = <InterfaceType>{};
  // check if the type's members have been visited already to avoid infinite loop
  visitedTypes ??= <InterfaceType>{};
  if (visitedTypes.contains(type)) {
    return set;
  } else {
    visitedTypes.add(type);
  }

  final members = type.element2.fields.whereType<VariableElement>().where((e) => !e.isPrivate);

  for (final member in members) {
    collectNonDartTypesFromType(member.type, set);
  }

  if (set.isNotEmpty) {
    final innerTypes = <InterfaceType>{};
    for (final t in set) {
      innerTypes.addAll(findAllNonDartTypesInTypeMembers(t, visitedTypes));
    }
    set.addAll(innerTypes);
  }

  return set;
}

/// Inspect if [type] is a non-Dart Type or Extract the non-Dart type(s) from type arguments if any.
///
/// e.g. `Future<List<User>> --> {User}
///      `Future<Map<User, UserData>> -> {User, UserData}
///      `UserData` -> {UserData}
///
void collectNonDartTypesFromType(DartType type, Set<InterfaceType> set) {
  if (type is InterfaceType) {
    if (isDartType(type)) {
      if (type.typeArguments.isNotEmpty) {
        for (final t in type.typeArguments) {
          collectNonDartTypesFromType(t, set);
        }
      }
    } else {
      set.add(type);
    }
  }
  return;
}

String? getTypePackageURI(InterfaceType type) {
  return type.element2.librarySource.uri.toString();
}

String getEndpointsPath(String projectPath) {
  final path = p.join(projectPath, 'mid', 'endpoints.dart');
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
