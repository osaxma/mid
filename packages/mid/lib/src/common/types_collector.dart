import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/common/models.dart';

import 'utils.dart';

/// TODO: simplify this mess since we created one function over the other over time.

/// see docs at [_findAllNonDartTypesFromMethodElement]
Set<InterfaceType> getAllNonDartTypes(List<ClassInfo> classInfos) {
  final types = <InterfaceType>{};
  for (final classInfo in classInfos) {
    for (final m in classInfo.methodInfos) {
      types.addAll(_findAllNonDartTypesFromMethodElement(m.methodElement));
    }
  }

  // remove duplicates of the same type (i.e. nullable vs non-nullable such Data vs Data?)
  final nonNullableTypes = types.where((element) => !isTypeNullable(element)).toSet(); // clone it

  for (final nonNullType in nonNullableTypes) {
    types.removeWhere((t) =>
        isTypeNullable(t) &&
        t.getDisplayString(withNullability: false) == nonNullType.getDisplayString(withNullability: false));
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
Set<InterfaceType> _findAllNonDartTypesFromMethodElement(MethodElement method) {
  final types = <InterfaceType>{};

  _collectNonDartTypesFromType(method.returnType, types);
  for (final para in method.parameters) {
    _collectNonDartTypesFromType(para.type, types);
  }

  final nonDartTypes = <InterfaceType>{};
  for (final t in types) {
    nonDartTypes.addAll(_findAllNonDartTypesInTypeMembers(t));
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
Set<InterfaceType> _findAllNonDartTypesInTypeMembers(InterfaceType type, [Set<InterfaceType>? visitedTypes]) {
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
    _collectNonDartTypesFromType(member.type, set);
  }

  if (set.isNotEmpty) {
    final innerTypes = <InterfaceType>{};
    for (final t in set) {
      innerTypes.addAll(_findAllNonDartTypesInTypeMembers(t, visitedTypes));
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
void _collectNonDartTypesFromType(DartType type, Set<InterfaceType> set) {
  if (type is InterfaceType) {
    if (isDartType(type) && !isEnum(type)) {
      if (type.typeArguments.isNotEmpty) {
        for (final t in type.typeArguments) {
          _collectNonDartTypesFromType(t, set);
        }
      }
    } else {
      set.add(type);
    }
  }
  return;
}
