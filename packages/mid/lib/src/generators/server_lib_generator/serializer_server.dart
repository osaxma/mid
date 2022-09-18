// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:analyzer/dart/element/type.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mid/src/common/types_collector.dart';
import 'package:mid/src/common/utils.dart';
import 'package:mid/src/generators/serializer_common.dart';
import 'package:mid/src/templates/create.dart';

// Notes:
// - The choice to create standalone serializers (i.e., not part of the type itself)
//  were for the following reasons:
//    - Avoid modifying the user code
//    - Support serializing external types (types from other packages)
//    - Support the use of external components (e.g. auth API or storage API components)
//
// - To avoid complexity in serialization process, the user defined types in return statement
//   or arguments must adhere to some rules:
//    - The type must have unnamed constructor with formal parameters (i.e., using `this` keyword).
//      e.g.:
//     ```dart
//        class Data {
//          final int id;
//          final String name;
//          final MetaData metadata; // must follow same rule including its members and their members, etc.
//
//          Data(this.id, this.name. this.metadata); // or named args
//        }
//    ```

/// Generates serialization code for non-Dart Types (i.e. none of the core types) for the server
///
///
/// The generator should be provided a list of all the available [types]. That is,
/// all the non-dart types used in any return statements or any arguments on the API server.
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
class ServerClassesSerializer {
  /// A set of all the available non-Dart types
  ///
  /// For `mid`, this mean the types for every return statement and argument.
  final Set<InterfaceType> types;

  ServerClassesSerializer({
    required this.types,
  });

  String generateCode() {
    final code = StringBuffer();
    final ignores = generateIgnoreForFile([unnecessaryImport, unusedImportLint]) + '\n';
    final imports = <String>{"import 'package:collection/collection.dart';"};

    for (final t in types) {
      final packagesURIs = getTypesImports(t);
      for (var p in packagesURIs) {
        imports.add("import '$p';");
      }

      if (isEnum(t)) {
        continue;
      }
      final toMap = _generateToMap(t);
      final fromMap = _generateFromMap(t);
      code.writeln(_classWrapper(t, toMap + '\n' + fromMap));
    }

    final source = ignores + imports.join('\n').toString() + code.toString();

    return DartFormatter(pageWidth: 120).format(source);
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
    late final String returnString;
    if (hasToMap(type)) {
      returnString = 'instance.toMap()';
    } else if (hasToJson(type)) {
      returnString = 'instance.toJson()';
    } else {
      final keyValues = _generateKeyValues(type, 'instance');
      returnString = '{$keyValues};';
    }

    return '''
static Map<String, dynamic> toMap($name instance) {
  return $returnString;
}
''';
  }

  String _generateKeyValues(InterfaceType type, String dataSource) {
    final paras = getGenerativeUnnamedConstructorParameters(type);
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
    late final String returnStatement;
    if (hasFromMap(type)) {
      returnStatement = '$name.fromMap(map)';
    } else if (hasFromJson(type)) {
      returnStatement = '$name.fromJson(map)';
    } else {
      final assignment = _generateFromMapAssignment(type);
      returnStatement = '$name($assignment)';
    }

    return ''' 
static $name fromMap(Map<String, dynamic> map) {
  return $returnStatement;
}
    ''';
  }

  String _generateFromMapAssignment(InterfaceType type) {
    final paras = getGenerativeUnnamedConstructorParameters(type);
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
}
