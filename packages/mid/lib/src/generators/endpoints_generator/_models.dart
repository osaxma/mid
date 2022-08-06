import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/common/extensions.dart';

// TODO: move all the types logic into TypeInfo (typeArguments, isFuture, isStream, hasToJson, packageURI, etc)
//       it's a bit messy now 


class ClassInfo {
  final String className;
  final String packageURI;
  final List<MethodInfo> methodInfos;

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
    final List<MethodInfo> endPointsInfo = [];
    for (var method in interfaceType.methods) {
      if (method.isPrivate) {
        continue;
      }
      endPointsInfo.add(MethodInfo.fromMethodElement(method));
    }

    return ClassInfo(
      className: interfaceType.getDisplayString(withNullability: false),
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
  final String methodName;
  final ReturnTypeInfo returnTypeInfo;
  final List<ArgumentInfo> argumentsInfo;

  // temp: keeping it handy for now
  // ignore: unused_field
  final MethodElement _methodElement;

  // bool get isFuture => returnTypeInfo.typeInfo.dartType.isDartAsyncFuture;
  // bool get isStream => returnTypeInfo.typeInfo.dartType.isDartAsyncStream;

  MethodInfo({
    required this.methodName,
    required this.returnTypeInfo,
    required this.argumentsInfo,
    required MethodElement methodElement,
  }) : _methodElement = methodElement;

  factory MethodInfo.fromMethodElement(MethodElement element) {
    final argumentsInfo = <ArgumentInfo>[];
    for (final p in element.parameters) {
      argumentsInfo.add(ArgumentInfo(parameterElement: p));
    }
    return MethodInfo(
      methodName: element.name,
      returnTypeInfo: ReturnTypeInfo.fromMethodElement(element),
      argumentsInfo: argumentsInfo,
      methodElement: element,
    );
  }
}

class ArgumentInfo {
  final ParameterElement _parameterElement;
  ArgumentInfo({
    required ParameterElement parameterElement,
  }) : _parameterElement = parameterElement;

  String get argName => _parameterElement.name;
  bool get isNamed => _parameterElement.isNamed;
  bool get isRequiredNamed => _parameterElement.isRequiredNamed;
  bool get isOptional => _parameterElement.isOptional;
  bool get isOptionalNamed => _parameterElement.isOptionalNamed;
  bool get hasDefaultValue => _parameterElement.hasDefaultValue;
  bool get isPositional => _parameterElement.isPositional;
  String? get defaultValue => _parameterElement.defaultValueCode;

  bool get typeContainsFromJsonConstructor {
    final type = _parameterElement.type;
    if (type is InterfaceType) {
      return type.constructors.any((element) => element.name == 'fromJson');
    }
    return false;
  }

  bool get typeContainsFromMapConstructor {
    final type = _parameterElement.type;
    if (type is InterfaceType) {
      return type.constructors.any((element) => element.name == 'fromMap');
    }
    return false;
  }

  // bool get containsToJson {
  //   final type = _parameterElement.type;
  //   if (type is InterfaceType) {
  //     return type.element.methods.any((element) => element.name == 'toJson');
  //   }

  //   return false;
  // }

  bool get isNullable => _parameterElement.type.nullabilitySuffix != NullabilitySuffix.none;

  String getType({bool withNullability = true}) {
    return _parameterElement.type.getDisplayString(withNullability: withNullability);
  }

  String? getTypePackageURI() {
    final type = _parameterElement.type;
    if (type is InterfaceType) {
      return type.element.librarySource.uri.toString();
    } 
    return null;
  }
  // int get position => _parameterElement.
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
class ReturnTypeInfo {
  final DartType _dartType;
  final List<DartType> typeArguments;

  bool get isStream => _dartType.isDartAsyncStream;
  bool get isFuture => _dartType.isDartAsyncFuture;
  bool get isList => _dartType.isDartCoreList || typeArguments.any((e) => e.isDartCoreList);
  bool get isSet => _dartType.isDartCoreSet || typeArguments.any((e) => e.isDartCoreSet);
  bool get isMap => _dartType.isDartCoreMap || typeArguments.any((e) => e.isDartCoreMap);

  bool get isVoid => _dartType.isVoid || typeArguments.any((element) => element.isVoid);

  ReturnTypeInfo({
    required DartType dartType,
    required this.typeArguments,
  }) : _dartType = dartType;

  factory ReturnTypeInfo.fromMethodElement(MethodElement element) {
    late final List<DartType> typeArgs;
    final returnType = element.returnType;
    if (returnType is InterfaceType) {
      typeArgs = returnType.typeArguments;
    } else {
      typeArgs = const <DartType>[];
    }
    return ReturnTypeInfo(
      dartType: returnType,
      typeArguments: typeArgs,
    );
  }

  bool get typeContainsToJsonMethod {
    final type = _dartType;
    if (type is InterfaceType) {
      return type.element.methods.any((element) => element.name == 'toJson');
    } else {
      for (final t in typeArguments) {
        if (t is InterfaceType) {
          if (t.element.methods.any((element) => element.name == 'toJson')) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool get typeContainsToMapMethod {
    final type = _dartType;
    if (type is InterfaceType) {
      return type.element.methods.any((element) => element.name == 'toMap');
    } else {
      for (final t in typeArguments) {
        if (t is InterfaceType) {
          if (t.element.methods.any((element) => element.name == 'toJson')) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

// class TypeInfo {
//   // info such as actual type (is it core type eg String int bool double num etc)
//   // is it a map
//   // is it Future or Stream
//   // is it serializable

//   final DartType dartType;
//   TypeInfo({
//     required this.dartType,
//   });
// }

// String generateReferenceURI(N)
