// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mid/src/common/analyzer.dart';

// todo: once this is working, clean up the client/server generator:
//       - ensure the generated functin is called per format
//       - import the appropriate file if serialization is in a separate file
//       - remove code searching for `toMap`/'toJson`/`fromMap`/`fromJson`

// note:
// the choice to create separate serializers were for the following reasons:
//  - prevent modifying the user code
//  - support external components (auth API or storage API)
//    - there's no way to generate code for an external package in such case.
//
// This introduces a limitation of course, all retrun types and arguments types must adhere to some rules:
//  - The type must have unnamed constructor where all final fields are avaialble using `this` keyword.
// that is all classes must be defined as follows:
/* 
class Data {
  final int id;
  final String name;
  final MetaData metadata;

  Data(this.id, this.name. this.metadata); // or named args using required. 
}
 */

/// Generates serialization code for non-Dart Types (i.e. none of the core types) for the server
///
///
/// The generator should be provided a list of all the available [types]. That is,
/// all the types used in any return statements or any arguments on the API server.
///
/// The generator will ensure each Type is generated only once in the following format:
///
/// ```dart
/// TypeNameSerializer {
///
///   static TypeName fromMap(Map<String, dynamic> map) {/*  */}
///
///   static Map<String, dynamic> toMap(TypeName instance) {/*  */}
/// }
/// ```
///
/// The generator will run recursively for non-Dart Type within the given list of types.
/// And it'll generate the code for them as well.
///
/// For instance, if the given type is the following:
/// ```dart
/// class User {
///     final int id;
///     final String name;
///     final UserData data;
/// }
/// ```
/// Where `UserData` was not supplied within `types`, the serializer will be generated for `UserData`.
/// In addition, if `UserData` contains another non-Dart type (e.g. `MetaData`), the serializer will
/// be generated for `MetaData` as well.
///
///
class ServerClassesSerializer {
  /// A set of all the available non-Dart types
  ///
  /// For `mid`, this mean the types for every return statement and argument.
  // note: should we use [TypeInfo] instead?
  final Set<InterfaceType> types;

  ServerClassesSerializer({
    required this.types,
  });

  /// Generates the standard name of the  `toMap` function based on [type]
  static String getSerializerName(InterfaceType type) {
    return type.getDisplayString(withNullability: false) + 'Serializer';
  }

  String generateCode() {
    final code = StringBuffer();
    final importBuffer = StringBuffer();

    for (final t in types) {
      final toMap = _generateToMap(t);
      final fromMap = _generateFromMap(t);
      code.writeln(_classWrapper(t, toMap + '\n' + fromMap));
      importBuffer.writeln("import '${getTypePackageURI(t)}';");
    }

    final source = importBuffer.toString() + code.toString();

    return DartFormatter().format(source);
  }

  String _classWrapper(InterfaceType type, String code) {
    return '''
class ${getSerializerName(type)} {
  $code
}
''';
  }

  /// generates:
  /// ```dart
  /// static Map<String, dynamic> toMap(User user) {
  ///   return {
  ///     'id': user.id,
  ///     'name': user.name,
  ///     'data': UserDataSerializer.toMap(user.data),
  ///   };
  /// }
  /// ```
  String _generateToMap(InterfaceType type) {
    final name = type.getDisplayString(withNullability: false);
    final keyValues = _generateKeyValues(type, 'instance');
    return '''
static Map<String, dynamic> toMap($name instance) {
  return {
    $keyValues
  };
}
''';
  }

  String _generateKeyValues(InterfaceType type, String dataSource) {
    final paras = _getConstructorParameters(type);
    final buff = StringBuffer();
    for (final para in paras) {
      final key = para.name;
      final paraType = para.type as InterfaceType;
      final value = serializeValue(paraType, '$dataSource.$key', useToMapFromMap: false);
      buff.writeln("'$key':$value,");
    }

    return buff.toString();
  }

  // String _generateMapValue(type)

  /// generates:
  /// ```dart
  /// static User fromMap(Map<String, dynamic> map) {
  ///   return User(
  ///     id: map['id'],
  ///     name: map['name'],
  ///     data: UserDataSerializer.fromMap(map['data']),
  ///     );
  /// }
  /// ```
  String _generateFromMap(InterfaceType type) {
    final name = type.getDisplayString(withNullability: false);
    final assignment = _generateFromMapAssignment(type);
    return ''' 
static $name fromMap(Map<String, dynamic> map) {
  return $name(
    $assignment
    );
}
    ''';
  }

  String _generateFromMapAssignment(InterfaceType type) {
    final paras = _getConstructorParameters(type);
    final buff = StringBuffer();
    for (final para in paras) {
      final argName = para.name;
      final argType = para.type as InterfaceType;
      // final typeName = argType.getDisplayString(withNullability: true);
      final argAssignment = deserializeValue(argType, "map['$argName']", useToMapFromMap: false);
      if (para.isPositional) {
        buff.writeln('$argAssignment,');
      } else {
        buff.writeln('$argName : $argAssignment,');
      }
    }

    return buff.toString();
  }

  List<ParameterElement> _getConstructorParameters(InterfaceType type) {
    // TODO: handle better -- we are looking for the unnamed generative constructor here
    return type.element.constructors.firstWhere((c) => c.isGenerative).parameters;
  }
}

// maybe move to TypeInfo
bool allArgumentsInUnnamedConstructorIsToThis(InterfaceType type) {
  final constructors = type.element.constructors.where((c) => c.isGenerative);

  if (constructors.isEmpty) {
    final name = type.getDisplayString(withNullability: false);
    final packageURI = type.element.librarySource.uri.toString();
    throw Exception('$name at does not have a generative constructor (package: $packageURI');
  }
  final constructor = constructors.first;

  constructor.parameters.any((p) => !p.isInitializingFormal);

  // [ParameterElement.isInitializingFormal] refers when a field is initialized using `this` keyword.
  return constructor.parameters.any((p) => !p.isInitializingFormal);
}

/// When [useToMapFromMap] is `true`, type.toMap() and Type.fromMap() (i.e. userData.toMap() & UserData.fromMap()).
/// When `false`, the Serializer is used (i.e. UserDataSerializer.toMap() & UserDataSerializer.fromMap()).
///
/// The first case is mainly used for the client side since it uses data classes whereas the second case is used
/// for the server since it uses the Serializer pattern.
String deserializeValue(DartType type, String value, {required bool useToMapFromMap}) {
  final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;
  final typeName = type.getDisplayString(withNullability: true);
  if (isBasicType(type) || type is! InterfaceType) {
    return '$value as $typeName';
  }

  if (isDateTime(type)) {
    if (isNullable) {
      return '$value == null ? null : DateTime.parse($value)';
    } else {
      return 'DateTime.parse($value)';
    }
  }

  if (isDuration(type)) {
    if (isNullable) {
      return '$value == null ? null : Duration(microseconds: $value)';
    } else {
      return 'Duration(microseconds: $value)';
    }
  }

  if (!isDartType(type)) {
    if (useToMapFromMap) {
      final className = type.getDisplayString(withNullability: false);
      if (isNullable) {
        return '$value == null ? null : $className.fromMap($value)';
      } else {
        return '$className.fromMap($value)';
      }
    } else {
      final serializerName = ServerClassesSerializer.getSerializerName(type);
      if (isNullable) {
        return '$value == null ? null : $serializerName.fromMap($value)';
      } else {
        return '$serializerName.fromMap($value)';
      }
    }
  }

  if (type.isDartCoreList || type.isDartCoreSet) {
    if (type.typeArguments.isEmpty) {
      return value;
    }
    final t = type.typeArguments.first as InterfaceType;
    final listOrSet = type.isDartCoreList ? 'List' : 'Set';
    final typeArg =
        type.typeArguments.isEmpty ? '' : '<${type.typeArguments.first.getDisplayString(withNullability: true)} >';
    final v = deserializeValue(t, 'x', useToMapFromMap: useToMapFromMap);
    if (isNullable) {
      return "$value == null ? null : $listOrSet$typeArg.from($value.map((x) => $v))";
    } else {
      return "$listOrSet$typeArg.from($value.map((x) => $v))";
    }
  }

  if (type.isDartCoreMap) {
    if (type.typeArguments.isEmpty) {
      return value;
    }
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    if (isBasicType(keyType) && isBasicType(valueType)) {
      return value;
    } else {
      final k = deserializeValue(keyType, 'k', useToMapFromMap: useToMapFromMap);
      final v = deserializeValue(valueType, 'v', useToMapFromMap: useToMapFromMap);
      if (isNullable) {
        return "$value?.map((k, v) => MapEntry($k, $v))";
      } else {
        return "$value.map((k, v) => MapEntry($k, $v))";
      }
    }
  }
  throw UnimplementedError();
}

/// When [useToMapFromMap] is `true`, type.toMap() and Type.fromMap() (i.e. userData.toMap() & UserData.fromMap()).
/// When `false`, the Serializer is used (i.e. UserDataSerializer.toMap() & UserDataSerializer.fromMap()).
///
/// The first case is mainly used for the client side since it uses data classes whereas the second case is used
/// for the server since it uses the Serializer pattern.
String serializeValue(DartType type, String value, {required bool useToMapFromMap}) {
  final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;
  if (isBasicType(type) || type is! InterfaceType) {
    return value;
  }

  if (isDateTime(type)) {
    if (isNullable) {
      return '$value?.toUtc().toIso8601String()';
    } else {
      return '$value.toUtc().toIso8601String()';
    }
  }

  if (isDuration(type)) {
    if (isNullable) {
      return '$value?.inMicroseconds';
    } else {
      return '$value.inMicroseconds';
    }
  }

  if (!isDartType(type)) {
    if (useToMapFromMap) {
      if (isNullable) {
        return '$value?.toMap()';
      } else {
        return '$value.toMap()';
      }
    } else {
      if (isNullable) {
        return '$value == null ? null : ${ServerClassesSerializer.getSerializerName(type)}.toMap($value)';
      } else {
        return '${ServerClassesSerializer.getSerializerName(type)}.toMap($value)';
      }
    }
  }

  if (type.isDartCoreList || type.isDartCoreSet) {
    if (type.typeArguments.isEmpty) {
      return value;
    }
    final t = type.typeArguments.first as InterfaceType;
    final v = serializeValue(t, 'x', useToMapFromMap: useToMapFromMap);
    if (isNullable) {
      return '$value?.map((x) => $v)';
    } else {
      return '$value.map((x) => $v)';
    }
  }

  if (type.isDartCoreMap) {
    if (type.typeArguments.isEmpty) {
      return value;
    }
    final keyType = type.typeArguments[0];
    final valueType = type.typeArguments[1];
    if (isBasicType(keyType) && isBasicType(valueType)) {
      return value;
    } else {
      final k = serializeValue(keyType, 'k', useToMapFromMap: useToMapFromMap);
      final v = serializeValue(valueType, 'v', useToMapFromMap: useToMapFromMap);
      if (isNullable) {
        return '$value?.map((k, v) => MapEntry($k, $v))';
      } else {
        return '$value.map((k, v) => MapEntry($k, $v))';
      }
    }
  }

  throw UnimplementedError();
}
