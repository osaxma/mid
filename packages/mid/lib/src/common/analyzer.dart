import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
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

const basicTypes = {
  'bool',
  'num',
  'int',
  'BigInt',
  'String',
  'double',
  'dynamic',
  'Object',
  'DateTime',
  'Duration',
};

const collectionTypes = {
  'Set',
  'Map',
  'List',
};

const coreTypes = {
  ...basicTypes,
  ...collectionTypes,
};

bool isDartType(DartType type) {
  return type.isDartAsyncFuture ||
      type.isDartAsyncFutureOr ||
      type.isDartAsyncStream ||
      type.isDartCoreBool ||
      type.isDartCoreDouble ||
      type.isDartCoreEnum ||
      type.isDartCoreFunction ||
      type.isDartCoreInt ||
      type.isDartCoreIterable ||
      type.isDartCoreList ||
      type.isDartCoreMap ||
      type.isDartCoreNull ||
      type.isDartCoreNum ||
      type.isDartCoreObject ||
      type.isDartCoreSet ||
      type.isDartCoreString ||
      type.isDartCoreSymbol ||
      type.isDynamic ||
      // type.isBottom || // ??
      type.isVoid;
}

bool isDateTimeOrDuration(DartType type) {
  final name = type.getDisplayString(withNullability: false);
  return name == 'DateTime' || name == 'Duration';
}

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

  types.addAll(extractNonDartTypes(method.returnType));
  for (final para in method.parameters) {
    types.addAll(extractNonDartTypes(para.type));
  }

  final nonDartTypes = <InterfaceType>{};
  for (final t in types) {
    nonDartTypes.addAll(findAllNonDartTypes(t));
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
Set<InterfaceType> findAllNonDartTypes(InterfaceType type) {
  final types = <InterfaceType>{};
  final members = type.element.fields.whereType<VariableElement>().where((element) => element.isFinal);

  for (final member in members) {
    final nonDartTypes = extractNonDartTypes(member.type);
    types.addAll(nonDartTypes);
  }

  if (types.isNotEmpty) {
    final innerTypes = <InterfaceType>{};
    for (final t in types) {
      innerTypes.addAll(findAllNonDartTypes(t));
    }
    types.addAll(innerTypes);
  }

  return types;
}

/// Inspect if [type] is a non-Dart Type or Extract the non-Dart type(s) from type arguments if any.
///
/// e.g. `Future<List<User>> --> {User}
///      `Future<Map<User, UserData>> -> {User, UserData}
///      `UserData` -> {UserData}
///
Set<InterfaceType> extractNonDartTypes(DartType type) {
  final set = <InterfaceType>{};
  if (type is InterfaceType) {
    if (isDartType(type) || isDateTimeOrDuration(type)) {
      if (type.typeArguments.isNotEmpty) {
        for (final t in type.typeArguments) {
          set.addAll(extractNonDartTypes(t));
        }
      }
    } else {
      set.add(type);
    }
  }
  return set;
}
