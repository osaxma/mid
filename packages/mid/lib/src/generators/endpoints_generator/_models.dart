import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/common/analyzer.dart';

import 'package:mid/src/common/extensions.dart';

import '_visitors.dart';

// TODO: move all the types logic into TypeInfo (typeArguments, isFuture, isStream, hasToJson, packageURI, etc)
//       it's a bit messy now

class ClassInfo {
  final String className;
  final String packageURI;
  final List<MethodInfo> methodInfos;

  String get classNameForClient => '${className}Client';

  // for now we treat all as post requests
  final String verb = 'POST';

  // temp: we keeping this here until we figure out what is needed it from it.
  final InterfaceType _interfaceType; // ignore: unused_field

  ClassInfo({
    required this.className,
    required this.packageURI,
    required this.methodInfos,
    required InterfaceType interfaceType,
  }) : _interfaceType = interfaceType;

  factory ClassInfo.fromInterfaceType(InterfaceType interfaceType) {
    final className = interfaceType.getDisplayString(withNullability: false);
    final List<MethodInfo> endPointsInfo = [];
    for (var method in interfaceType.methods) {
      if (method.isPrivate || _hasServerOnlyAnnotation(method)) {
        continue;
      }

      endPointsInfo.add(MethodInfo.fromMethodElement(method, className));
    }

    return ClassInfo(
      className: className,
      packageURI: interfaceType.element.librarySource.uri.toString(),
      methodInfos: endPointsInfo,
      interfaceType: interfaceType,
    );
  }

  List<String> getRoutes() {
    final routes = <String>[];
    for (var e in methodInfos) {
      routes.add('${className.toSnakeCaseFromPascalCase()}/${e.methodName.toSnakeCaseFromCamelCase()}');
    }
    return routes;
  }

  // String get
}

class MethodInfo {
  /// The name of the class where this method is
  final String className;
  final String methodName;
  final TypeInfo returnTypeInfo;
  final List<ArgumentInfo> argumentsInfo;

  // temp: keeping it handy for now
  // ignore: unused_field
  final MethodElement _methodElement;

  String get source => _methodElement.source.toString();

  MethodInfo({
    required this.className,
    required this.methodName,
    required this.returnTypeInfo,
    required this.argumentsInfo,
    required MethodElement methodElement,
  }) : _methodElement = methodElement;

  factory MethodInfo.fromMethodElement(MethodElement element, String className) {
    final argumentsInfo = <ArgumentInfo>[];
    for (final p in element.parameters) {
      argumentsInfo.add(ArgumentInfo(parameterElement: p));
    }
    return MethodInfo(
      className: className,
      methodName: element.name,
      returnTypeInfo: TypeInfo.fromDartType(element.returnType), // ReturnTypeInfo.fromMethodElement(element),
      argumentsInfo: argumentsInfo,
      methodElement: element,
    );
  }

  // In Dart, the convention is that classes are PascalCase and methods are camelCase
  // we convert both to snake_case (this can be made optional)
  // TODO(@osaxma): figure out if we need to have a `/` at the end of the route
  // note: the route must start with `/`
  String get routeName => '/${className.toSnakeCaseFromPascalCase()}/${methodName.toSnakeCaseFromCamelCase()}/';
}

class ArgumentInfo {
  final ParameterElement _parameterElement;
  final TypeInfo type;

  ArgumentInfo({
    required ParameterElement parameterElement,
  })  : _parameterElement = parameterElement,
        type = TypeInfo.fromDartType(parameterElement.type);

  String get argName => _parameterElement.name;
  bool get isNamed => _parameterElement.isNamed;
  bool get isRequired => _parameterElement.isRequired;
  bool get isRequiredNamed => _parameterElement.isRequiredNamed;
  bool get isOptional => _parameterElement.isOptional;
  bool get isOptionalNamed => _parameterElement.isOptionalNamed;
  bool get hasDefaultValue => _parameterElement.hasDefaultValue;
  bool get isPositional => _parameterElement.isPositional;
  String? get defaultValue => _parameterElement.defaultValueCode;

  // bool get typeContainsFromJsonConstructor {
  //   final type = _parameterElement.type;
  //   if (type is InterfaceType) {
  //     return type.constructors.any((element) => element.name == 'fromJson');
  //   }
  //   return false;
  // }

  // bool get typeContainsFromMapConstructor {
  //   final type = _parameterElement.type;
  //   if (type is InterfaceType) {
  //     return type.constructors.any((element) => element.name == 'fromMap');
  //   }
  //   return false;
  // }

  // // bool get containsToJson {
  // //   final type = _parameterElement.type;
  // //   if (type is InterfaceType) {
  // //     return type.element.methods.any((element) => element.name == 'toJson');
  // //   }

  // //   return false;
  // // }

  // bool get isNullable => _parameterElement.type.nullabilitySuffix != NullabilitySuffix.none;

  // String getType({bool withNullability = true}) {
  //   return _parameterElement.type.getDisplayString(withNullability: withNullability);
  // }

  // String? getTypePackageURI() {
  //   final type = _parameterElement.type;
  //   if (type is InterfaceType) {
  //     return type.element.librarySource.uri.toString();
  //   }
  //   return null;
  // }
  // int get position => _parameterElement.
}

// works only with resolved elements
bool _hasServerOnlyAnnotation(Element element) {
  return element.metadata.any((element) {
    return element.element?.displayName == 'serverOnly';
  });
}

class TypeInfo {
  /// The main type which holds all the type arugments
  final DartType _type;

  /// Whether this type is a void or one of its type arguments is a void type e.g. void or Future<void>
  final bool isVoid;

  /// Whether this type or one of its type arguments is a core type e.g. int or Future<String> or Stream<List<double>>
  ///
  /// Basic types are: bool, num, double, int, BigInt, String, DateTime, Duration, dynamic, Object
  final bool isBasicType;

  /// refers to toJson method
  final bool hasToJson;

  /// refers to toMap method
  final bool hasToMap;

  /// refers to Type.fromJson factory constructor
  final bool hasFromJson;

  /// refers to Type.fromMap factory constructor
  final bool hasFromMap;

  /// if this type is a Future
  final bool isFuture;

  /// if this type is a Stream
  final bool isStream;

  /// Whether this type or one of its type arguments is an iterable
  final bool isIterable;

  /// Whether this type or one of its type arguments is a List
  final bool isList;

  /// Whether this type or one of its type arguments is a Set
  final bool isSet;

  /// Whether this type or one of its type arguments is a Map
  final bool isMap;

  /// Whether this type or one of its type arguments is a DateTime
  final bool isDateTime;

  /// Whether this type or one of its type arguments is a Duration
  final bool isDuration;

  final bool hasTypeArguments;

  final int typeArgumentsCount;

  TypeInfo({
    required DartType type,
    required this.isVoid,
    required this.isBasicType,
    required this.hasToJson,
    required this.hasToMap,
    required this.hasFromJson,
    required this.hasFromMap,
    required this.isFuture,
    required this.isStream,
    required this.isIterable,
    required this.isList,
    required this.isSet,
    required this.isMap,
    required this.isDateTime,
    required this.isDuration,
    required this.hasTypeArguments,
    required this.typeArgumentsCount,
  }) : _type = type;

  factory TypeInfo.fromDartType(DartType type) {
    if (type is! InterfaceType) {
      throw Exception('expected an interfaceType');
    }

    return TypeInfo(
      type: type,
      isVoid: type.isVoid || type.typeArguments.any((element) => element.isVoid),
      isBasicType: type.isVoid || type.typeArguments.any((element) => element.isVoid),
      hasToJson: typeContainsToJsonMethod(type) || type.typeArguments.any((t) => typeContainsToJsonMethod(t)),
      hasToMap: typeContainsToMapMethod(type) || type.typeArguments.any((t) => typeContainsToMapMethod(t)),
      hasFromJson:
          typeContainsFromJsonConstructor(type) || type.typeArguments.any((t) => typeContainsFromJsonConstructor(t)),
      hasFromMap:
          typeContainsFromMapConstructor(type) || type.typeArguments.any((t) => typeContainsFromMapConstructor(t)),
      isFuture: type.isDartAsyncFuture,
      isStream: type.isDartAsyncStream,
      isIterable: type.isDartCoreIterable || type.typeArguments.any((element) => element.isDartCoreIterable),
      isList: type.isDartCoreList || type.typeArguments.any((element) => element.isDartCoreList),
      isSet: type.isDartCoreSet || type.typeArguments.any((element) => element.isDartCoreSet),
      isMap: type.isDartCoreMap || type.typeArguments.any((element) => element.isDartCoreMap),
      isDateTime: isTypeADateTime(type) || type.typeArguments.any((t) => isTypeADateTime(t)),
      isDuration: isTypeADuration(type) || type.typeArguments.any((t) => isTypeADuration(t)),
      hasTypeArguments: type.typeArguments.isNotEmpty,
      typeArgumentsCount: type.typeArguments.length,
    );
  }

  static bool typeContainsToJsonMethod(DartType type) {
    if (type is InterfaceType) {
      if (type.element.methods.any((element) => element.name == 'toJson')) {
        return true;
      }
    }
    return false;
  }

  static bool typeContainsToMapMethod(DartType type) {
    if (type is InterfaceType) {
      if (type.element.methods.any((element) => element.name == 'toMap')) {
        return true;
      }
    }
    return false;
  }

  static bool typeContainsFromJsonConstructor(DartType type) {
    if (type is InterfaceType) {
      return type.constructors.any((element) => element.name == 'fromJson');
    }
    return false;
  }

  static bool typeContainsFromMapConstructor(DartType type) {
    if (type is InterfaceType) {
      return type.constructors.any((element) => element.name == 'fromMap');
    }
    return false;
  }

  static bool isTypeABasicType(DartType type) {
    return basicTypes.any((element) => element == type.getDisplayString(withNullability: false));
  }

  static bool isTypeADateTime(DartType type) {
    return type.getDisplayString(withNullability: false) == 'DateTime';
  }

  static bool isTypeADuration(DartType type) {
    return type.getDisplayString(withNullability: false) == 'Duration';
  }

  bool get isNullable => _type.nullabilitySuffix != NullabilitySuffix.none;

  String getTypeName({
    bool withNullability = true,
    bool removeFutureAndStream = false,
  }) {
    return _type.getDisplayString(withNullability: withNullability);
  }

  String? getTypePackageURI() {
    final type = _type;
    if (type is InterfaceType) {
      return type.element.librarySource.uri.toString();
    }
    return null;
  }

  /// If the value is a core type (bool, String, num, double, int), then it'll return [dataSourceName] as is.
  ///
  /// If it's a DateTime, it'll return: DateTime.parse(dataSourceName)
  ///
  /// if it's a serializable class, it'll return: Data.fromMap(dataSourceName) or Data.fromJson(dataSourceName)
  ///
  /// if it's an iterable, it'll return something like: List<Data>.from(dataSourceName.map((x) => Data.fromMap(x)))
  ///
  String generateVariableAssignmentForType(String dataSourceName) {
    if (!isIterable) {
      if (isBasicType) {
        return _generateVariableAssignmentForBasicType(dataSourceName);
      } else {
        return _generateVariableAssignmentForSerializableType(dataSourceName);
      }
    }

    // Issue here if the type is a Future<List<Type>>> -- we need to account for type arguments 
    // mainly for returnTypes 
    if (isList) {
      final type = getTypeName();
      String statement;
      if (isBasicType) {
        final value = _generateVariableAssignmentForBasicType('x');
        statement = 'List<$type>.from($dataSourceName.map((x) => $value))';
      } else {}
    }

    throw UnimplementedError();
  }

  String _generateVariableAssignmentForBasicType(String dataSourceName) {
    String statement;
    if (isDateTime) {
      statement = 'DateTime.parse($dataSourceName)';
    } else if (isDuration) {
      statement = 'Duration(microseconds: $dataSourceName)';
    } else {
      statement = dataSourceName;
    }
    if (isNullable) {
      return '$dataSourceName != null ? $statement : null';
    } else {
      return statement;
    }
  }

  String _generateVariableAssignmentForSerializableType(String dataSourceName) {
    String statement;
    final name = getTypeName(withNullability: false);
    if (hasFromMap) {
      statement = '$name.fromMap($dataSourceName)';
    } else {
      statement = '$name.fromJson($dataSourceName)';
    }

    if (isNullable) {
      return '$dataSourceName != null ? $statement : null';
    } else {
      return statement;
    }
  }

  @override
  // TODO: implement hashCode
  int get hashCode => _type.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other is TypeInfo) {
      return _type == other._type;
    }

    return false;
  }
}

// the return type can be multiple things:
//
// void
// Type
// SerializableType
// Future<void>
// Future<Type> or Future<SerializableType>
// Stream<Type> or Stream<SerializableType>
// Iterable<Type>
// Future<Iterable<Type>> or Stream<Iterable<Type>>
// Future<Iterable<SerializableType>> or Stream<Iterable<SerializableType>>
// class ReturnTypeInfo {
//   final DartType _dartType;
//   final List<DartType> typeArguments;

//   bool get isStream => _dartType.isDartAsyncStream;
//   bool get isFuture => _dartType.isDartAsyncFuture;
//   bool get isList => _dartType.isDartCoreList || typeArguments.any((e) => e.isDartCoreList);
//   bool get isSet => _dartType.isDartCoreSet || typeArguments.any((e) => e.isDartCoreSet);
//   bool get isMap => _dartType.isDartCoreMap || typeArguments.any((e) => e.isDartCoreMap);
//   bool get isDateTime {
//     return _dartType.getDisplayString(withNullability: false) == 'DateTime' ||
//         typeArguments.any((e) => e.getDisplayString(withNullability: false) == 'DateTime');
//   }

//   bool get isVoid => _dartType.isVoid || typeArguments.any((element) => element.isVoid);

//   ReturnTypeInfo({
//     required DartType dartType,
//     required this.typeArguments,
//   }) : _dartType = dartType;

//   factory ReturnTypeInfo.fromMethodElement(MethodElement element) {
//     late final List<DartType> typeArgs;
//     final returnType = element.returnType;
//     if (returnType is InterfaceType) {
//       typeArgs = returnType.typeArguments;
//     } else {
//       typeArgs = const <DartType>[];
//     }
//     return ReturnTypeInfo(
//       dartType: returnType,
//       typeArguments: typeArgs,
//     );
//   }

//   bool get typeContainsToJsonMethod {
//     final type = _dartType;
//     if (type is InterfaceType) {
//       if (type.element.methods.any((element) => element.name == 'toJson')) {
//         return true;
//       }
//     }

//     for (final t in typeArguments) {
//       if (t is InterfaceType) {
//         if (t.element.methods.any((element) => element.name == 'toJson')) {
//           return true;
//         }
//       }
//     }

//     return false;
//   }

//   bool get typeContainsToMapMethod {
//     final type = _dartType;

//     if (type is InterfaceType) {
//       if (type.element.methods.any((element) => element.name == 'toMap')) {
//         return true;
//       }
//     }

//     for (final t in typeArguments) {
//       if (t is InterfaceType) {
//         if (t.element.methods.any((element) => element.name == 'toJson')) {
//           return true;
//         }
//       }
//     }

//     return false;
//   }
// }
