import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mid/src/common/extensions.dart';

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
      type.constructors.any((element) => element.name == 'fromJson');
    }
    return false;
  }

  bool get typeContainsFromMapConstructor {
    final type = _parameterElement.type;
    if (type is InterfaceType) {
      type.constructors.any((element) => element.name == 'fromMap');
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
  // int get position => _parameterElement.
}

class ReturnTypeInfo {
  final TypeInfo typeInfo;
  ReturnTypeInfo({required this.typeInfo});

  factory ReturnTypeInfo.fromMethodElement(MethodElement element) {
    print('return type = ${element.returnType.getDisplayString(withNullability: true)}');
    print('return type alias = ${element.returnType.alias?.typeArguments}');
    return ReturnTypeInfo(
        typeInfo: TypeInfo(
      dartType: element.returnType,
    ));
  }

  bool get isFuture => typeInfo.dartType.isDartAsyncFuture;
  bool get isStream => typeInfo.dartType.isDartAsyncStream;

  bool get isVoid {
    if (isFuture || isStream) {
      // typeInfo.dartType.
    }
    return typeInfo.dartType.isVoid;
  }

  bool get typeContainsToJsonMethod {
    final type = typeInfo.dartType;
    if (type is InterfaceType) {
      return type.element.methods.any((element) => element.name == 'toJson');
    }
    return false;
  }

  bool get typeContainsToMapMethod {
    final type = typeInfo.dartType;
    if (type is InterfaceType) {
      return type.element.methods.any((element) => element.name == 'toMap');
    }
    return false;
  }
}

class TypeInfo {
  // info such as actual type (is it core type eg String int bool double num etc)
  // is it a map
  // is it Future or Stream
  // is it serializable

  final DartType dartType;
  TypeInfo({
    required this.dartType,
  });
}

// String generateReferenceURI(N)
