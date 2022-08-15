// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:mid/src/common/analyzer.dart';
import 'package:mid/src/common/models.dart';

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

    return importBuffer.toString() + '\n' + code.toString();
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
      final value = _generateKeyAssignment(paraType, '$dataSource.$key');
      buff.writeln("'$key':$value,");
    }

    return buff.toString();
  }

  String _generateKeyAssignment(InterfaceType type, String dataSource) {
    final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;
    if (isBasicType(type)) {
      return dataSource;
    }

    if (isDateTime(type)) {
      if (isNullable) {
        return '$dataSource?.toUtc().toIso8601String()';
      } else {
        return '$dataSource.toUtc().toIso8601String()';
      }
    }

    if (isDuration(type)) {
      if (isNullable) {
        return '$dataSource?.inMicroseconds';
      } else {
        return '$dataSource.inMicroseconds';
      }
    }

    if (!isDartType(type)) {
      if (isNullable) {
        return ' $dataSource == null ? null : ${getSerializerName(type)}.toMap($dataSource)';
      } else {
        return '${getSerializerName(type)}.toMap($dataSource)';
      }
    }

    if (type.isDartCoreList || type.isDartCoreSet) {
      if (type.typeArguments.isEmpty) {
        return dataSource;
      }
      final t = type.typeArguments.first as InterfaceType;

      if (isNullable) {
        return '$dataSource?.map((x) => ${_generateKeyAssignment(t, 'x')})';
      } else {
        return '$dataSource.map((x) => ${_generateKeyAssignment(t, 'x')})';
      }
    }

    if (type.isDartCoreMap) {
      if (type.typeArguments.isEmpty) {
        return dataSource;
      }
      final keyType = type.typeArguments[0] as InterfaceType;
      final valueType = type.typeArguments[0] as InterfaceType;
      if (isBasicType(keyType) && isBasicType(valueType)) {
        return dataSource;
      } else {
        if (isNullable) {
          return '$dataSource?.map((k, v) => MapEntry(${_generateKeyAssignment(keyType, 'k')}, ${_generateKeyAssignment(valueType, 'v')}))';
        } else {
          return '$dataSource.map((k, v) => MapEntry(${_generateKeyAssignment(keyType, 'k')}, ${_generateKeyAssignment(valueType, 'v')}))';
        }
      }
    }

    throw UnimplementedError();
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
      final argAssignment = _generateArgumentAssignment(argType, "map['$argName']");
      buff.writeln('$argName : $argAssignment,');
    }

    return buff.toString();
  }

  String _generateArgumentAssignment(InterfaceType type, String argName) {
    final isNullable = type.nullabilitySuffix != NullabilitySuffix.none;
    final typeName = type.getDisplayString(withNullability: true);
    if (isBasicType(type)) {
      return '$argName as $typeName';
    }

    if (isDateTime(type)) {
      if (isNullable) {
        return '$argName == null ? null : DateTime.parse($argName)';
      } else {
        return 'DateTime.parse($argName)';
      }
    }

    if (isDuration(type)) {
      if (isNullable) {
        return '$argName == null ? null : Duration(microseconds: $argName)';
      } else {
        return 'Duration(microseconds: $argName)';
      }
    }

    if (!isDartType(type)) {
      final serializerName = getSerializerName(type);
      if (isNullable) {
        return '$argName == null ? null : $serializerName.fromMap($argName)';
      } else {
        return '$serializerName.fromMap($argName)';
      }
    }

    if (type.isDartCoreList || type.isDartCoreSet) {
      if (type.typeArguments.isEmpty) {
        return argName;
      }
      final t = type.typeArguments.first as InterfaceType;
      final typeName = type.getDisplayString(withNullability: false);

      if (isNullable) {
        return "$argName == null ? null : List<$typeName>.from($argName.map((x) => ${_generateArgumentAssignment(t, 'x')})";
      } else {
        return "List<$typeName>.from($argName.map((x) => ${_generateArgumentAssignment(t, 'x')})";
      }
    }

    if (type.isDartCoreMap) {
      if (type.typeArguments.isEmpty) {
        return argName;
      }
      final keyType = type.typeArguments[0] as InterfaceType;
      final valueType = type.typeArguments[0] as InterfaceType;
      if (isBasicType(keyType) && isBasicType(valueType)) {
        return argName;
      } else {
        if (isNullable) {
          return "$argName.map((k, v) => MapEntry(${_generateArgumentAssignment(keyType, 'k')} , ${_generateArgumentAssignment(valueType, 'v')})";
        } else {
          return "$argName?.map((k, v) => MapEntry(${_generateArgumentAssignment(keyType, 'k')} , ${_generateArgumentAssignment(valueType, 'v')})";
        }
      }
    }
    throw UnimplementedError();
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
