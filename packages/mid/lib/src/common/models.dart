import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/common/analyzer.dart';

import 'package:mid/src/common/extensions.dart';

import 'visitors.dart';

// TODO: re-evaluate if these wrappers since they were created in the early prototype
//       some stuff are redundant and in many casses other part of the program needs access
//       to the types and elements from the analyzer pkg (e.g. InterfaceType or MethodElement).

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
      if (method.isPrivate || elementHasAnnotation(method, 'serverOnly')) {
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
    for (var m in methodInfos) {
      routes.add(m.routeName);
    }
    return routes;
  }
}

class MethodInfo {
  /// The name of the class where this method is
  final String className;
  final String methodName;
  final TypeInfo returnTypeInfo;
  final List<ArgumentInfo> argumentsInfo;

  // temp: keeping it handy for now
  // ignore: unused_field
  final MethodElement methodElement;

  String get source => methodElement.source.toString();

  MethodInfo({
    required this.className,
    required this.methodName,
    required this.returnTypeInfo,
    required this.argumentsInfo,
    required MethodElement methodElement,
  }) : this.methodElement = methodElement;

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
  bool get isOptional => _parameterElement.isOptional;
  bool get isPositional => _parameterElement.isPositional;
  bool get isRequiredNamed => _parameterElement.isRequiredNamed;
  bool get isOptionalNamed => _parameterElement.isOptionalNamed;
  bool get hasDefaultValue => _parameterElement.hasDefaultValue;
  String? get defaultValue => _parameterElement.defaultValueCode;
}

// TODO: must of the getters here returns incorrect values for nested typeArguments
//    e.g. Future<List<Data>> -- hasToJson/hasToMap will return false even if Data has them
//     here we have three types:
//     Future -> typeArguments is 1 (i.e. List)
//     List -> typeArguments is 1 (i.e. Data)
//     Data -> typeArguments is 0
//
//     Initially i thought all the type arguments are held within Future. Tho the typeArguments
//     refers to the argument of the type itself (e.g. Map<String, dynamic> has two arguments)
//
//     we need to handle this nested use cases to make sure the generated code is accurate.
//
//     also how would we handle Maps of non-Basic Types (e.g. Map<User, Data>) or similar?
//     we should broadcast that it's not supported initially until it's figured out

class TypeInfo {
  /// The main type which holds all the type arugments
  // note: While in most cases we deal with [InterfaceType] (i.e. any class), void is not one for instance.
  final DartType dartType;

  /// Returns `true` if this type or one of its type arguments is a `void`
  final bool hasVoid;

  /// Returns `true` if this type or one of its type arguments is a basic type
  ///
  /// Basic types are: bool, num, double, int, BigInt, String, DateTime, Duration, dynamic, Object
  /// see [basicTypes]
  final bool hasBasicType;

  /// Returns `true` if this type or one of its argument has `toJson` method
  final bool hasToJson;

  /// Returns `true` if this type or one of its argument has `toMap` method
  final bool hasToMap;

  /// Returns `true` if this type or one of its argument has `fromJson` constructor
  final bool hasFromJson;

  /// Returns `true` if this type or one of its argument has `fromMap` constructor
  final bool hasFromMap;

  /// Returns `true` if this type is a Future
  final bool isFuture;

  /// Returns `true` if this type is a Stream
  final bool isStream;

  /// Returns `true` this type or one of its type arguments is an iterable
  final bool hasIterable;

  /// Returns `true` this type or one of its type arguments is a List
  final bool hasList;

  /// Returns `true` this type or one of its type arguments is a Set
  final bool hasSet;

  /// Returns `true` this type or one of its type arguments is a Map
  final bool hasMap;

  /// Returns `true` this type or one of its type arguments is a DateTime
  final bool hasDateTime;

  /// Returns `true` this type or one of its type arguments is a Duration
  final bool hasDuration;

  /// A flattened list of all the type arguments
  ///
  /// e.g. Future<List<Type> => [Future<List<Type>, List<Type>, Type]
  /// e.g. Future<Map<String, dynamic>> => [Future<Map<String, dynamic>>, Map<String, dynamic>, String, dynamic];
  final List<DartType> typeArguments;

  TypeInfo({
    required this.dartType,
    required this.hasVoid,
    required this.hasBasicType,
    required this.hasToJson,
    required this.hasToMap,
    required this.hasFromJson,
    required this.hasFromMap,
    required this.isFuture,
    required this.isStream,
    required this.hasIterable,
    required this.hasList,
    required this.hasSet,
    required this.hasMap,
    required this.hasDateTime,
    required this.hasDuration,
    required this.typeArguments,
  });

  factory TypeInfo.fromDartType(DartType type) {
    final typeArgs = extractAllTypeArguments(type);

    return TypeInfo(
      dartType: type,
      hasVoid: type.isVoid || typeArgs.any((element) => element.isVoid),
      hasBasicType: isBasicType(type) || typeArgs.any(isBasicType),
      hasToJson: containsToJsonMethod(type) || typeArgs.any(containsToJsonMethod),
      hasToMap: containsToMapMethod(type) || typeArgs.any(containsToMapMethod),
      hasFromJson: containsFromJsonConstructor(type) || typeArgs.any(containsFromJsonConstructor),
      hasFromMap: containsFromMapConstructor(type) || typeArgs.any(containsFromMapConstructor),
      isFuture: type.isDartAsyncFuture,
      isStream: type.isDartAsyncStream,
      hasIterable: type.isDartCoreIterable || typeArgs.any((element) => element.isDartCoreIterable),
      hasList: type.isDartCoreList || typeArgs.any((element) => element.isDartCoreList),
      hasSet: type.isDartCoreSet || typeArgs.any((element) => element.isDartCoreSet),
      hasMap: type.isDartCoreMap || typeArgs.any((element) => element.isDartCoreMap),
      hasDateTime: isDateTime(type) || typeArgs.any(isDateTime),
      hasDuration: isDuration(type) || typeArgs.any(isDuration),
      typeArguments: typeArgs,
    );
  }

  static List<DartType> extractAllTypeArguments(DartType type, [List<DartType>? initialList]) {
    final args = initialList ?? <DartType>[];
    args.add(type);
    if (type is InterfaceType) {
      for (var t in type.typeArguments) {
        extractAllTypeArguments(t, args);
      }
    }
    return args;
  }

  static bool containsToJsonMethod(DartType type) {
    if (type is InterfaceType) {
      if (type.element.methods.any((element) => element.name == 'toJson')) {
        return true;
      }
    }
    return false;
  }

  static bool containsToMapMethod(DartType type) {
    if (type is InterfaceType) {
      if (type.element.methods.any((element) => element.name == 'toMap')) {
        return true;
      }
    }
    return false;
  }

  static bool containsFromJsonConstructor(DartType type) {
    if (type is InterfaceType) {
      return type.constructors.any((element) => element.name == 'fromJson');
    }
    return false;
  }

  static bool containsFromMapConstructor(DartType type) {
    if (type is InterfaceType) {
      return type.constructors.any((element) => element.name == 'fromMap');
    }
    return false;
  }

  static bool isBasicType(DartType type) {
    return basicTypes.any((element) => element == type.getDisplayString(withNullability: false));
  }

  static bool isDateTime(DartType type) {
    return type.getDisplayString(withNullability: false) == 'DateTime';
  }

  static bool isDuration(DartType type) {
    return type.getDisplayString(withNullability: false) == 'Duration';
  }

  // static bool isIterable(DartType type) => type.isDartCoreList || type.isDartCoreMap || type.isDartCoreSet || type.isDartCoreIterable;

  static bool isNullableType(DartType type) => type.nullabilitySuffix != NullabilitySuffix.none;

  // bool get isNullable => dartType.nullabilitySuffix != NullabilitySuffix.none;

  /// Returns the full type name e.g. Future<List<Data>>
  ///
  /// If [skipFutureAndStream], then the inner types are returned.
  // String getTypeName({bool withNullability = true, bool skipFutureAndStream = false}) {
  //   if (skipFutureAndStream) {
  //     if (isFuture || isStream) {
  //       return typeArguments.first.getDisplayString(withNullability: withNullability);
  //     }
  //   }
  //   return dartType.getDisplayString(withNullability: withNullability);
  // }

  // String? getTypePackageURI() {
  //   final type = dartType;
  //   if (type is InterfaceType) {
  //     return type.element.librarySource.uri.toString();
  //   }
  //   return null;
  // }

  /// Generate a variable assignment -- mainly from a decoded JSON object
  ///
  /// If the value is a core type (bool, String, num, double, int), then it'll return [dataSourceName] as is.
  ///
  /// If it's a DateTime, it'll return: DateTime.parse(dataSourceName)
  ///
  /// if it's a serializable class, it'll return: Data.fromMap(dataSourceName) or Data.fromJson(dataSourceName)
  ///
  /// if it's an iterable, it'll return something like: List<Data>.from(dataSourceName.map((x) => Data.fromMap(x)))
  ///
  String generateVariableAssignmentForType(String dataSourceName) {
    late final DartType type;
    if (isFuture || isStream) {
      type = typeArguments[1];
    } else {
      type = typeArguments[0];
    }

    if (type.isVoid) {
      // TODO: make sure this is working as intended (i.e. an empty return statement).
      return '';
    }

    if (!hasList && !hasMap && !hasSet) {
      if (hasBasicType) {
        return _generateVariableAssignmentForBasicType(dataSourceName, type);
      } else {
        return _generateVariableAssignmentForSerializableType(dataSourceName, type);
      }
    }

    if (hasList) {
      final index = typeArguments.indexWhere((element) => element.isDartCoreList) + 1;
      final type = typeArguments[index];
      final typeName = type.getDisplayString(withNullability: false);
      String statement;
      if (isBasicType(type)) {
        final value = _generateVariableAssignmentForBasicType('x', type);
        statement = 'List<$typeName>.from($dataSourceName.map((x) => $value))';
      } else {
        final value = _generateVariableAssignmentForSerializableType('x', type);
        statement = 'List<$typeName>.from($dataSourceName.map((x) => $value))';
      }

      return statement;
    }

    // TODO: handle Sets and Maps -- also Map's arguments (e.g. if the return is something like: Map<User, Data> :/ )
    // note: json.decode() does not accept a Set and it has to be converted into list (i.e. set.toList()).

    throw UnimplementedError();
  }

  // static to avoid accessing instance members by mistake
  static String _generateVariableAssignmentForBasicType(String dataSourceName, DartType type) {
    String statement;
    if (isDateTime(type)) {
      // TODO: handle timezone .. within mid, it should be all UTC..
      //       we might need to check if the 'Z' is included or a specific timezone (+03:00)
      //       sqlite3 for instance does not include the timezone in its value
      //       if we parse as is, then it'll parse as local time instead of utc
      statement = 'DateTime.parse($dataSourceName)';
    } else if (isDuration(type)) {
      statement = 'Duration(microseconds: $dataSourceName)';
    } else {
      statement = dataSourceName;
    }
    // to avoid an issue of a double being decoded as an int (e.g. 1.0 -> 1) which happens on web
    // we need to cast here.
    final typeName = type.getDisplayString(withNullability: false);
    if (isNullableType(type)) {
      return '$dataSourceName != null ? $statement as $typeName : null';
    } else {
      return '$statement as $typeName';
    }
  }

  // static to avoid accessing instance members by mistake
  static String _generateVariableAssignmentForSerializableType(String dataSourceName, DartType type) {
    String statement;
    final name = type.getDisplayString(withNullability: false);
    if (containsFromMapConstructor(type)) {
      statement = '$name.fromMap($dataSourceName)';
    } else if (containsFromJsonConstructor(type)) {
      statement = '$name.fromJson($dataSourceName)';
    } else {
      throw Exception('Unknown type $name that was expected to have fromMap or fromJson constructor');
    }

    if (isNullableType(type)) {
      return '$dataSourceName != null ? $statement : null';
    } else {
      return statement;
    }
  }

  @override
  // TODO: implement hashCode
  int get hashCode => dartType.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other is TypeInfo) {
      return dartType == other.dartType;
    }

    return false;
  }
}
