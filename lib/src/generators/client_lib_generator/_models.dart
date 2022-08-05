import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

class BaseRouteInfo {
  final String name;
  final String packageURI;
  final List<EndPointInfo> endpointsInfo;

  // for now we treat all as post requests
  final String verb = 'POST';

  BaseRouteInfo({required this.name, required this.packageURI, required this.endpointsInfo});

  factory BaseRouteInfo.fromInterfaceType(InterfaceType interfaceType) {
    final List<EndPointInfo> endPointsInfo = [];
    for (var method in interfaceType.methods) {
      if (method.isPrivate) {
        continue;
      }
      endPointsInfo.add(EndPointInfo.fromMethodElement(method));
    }

    return BaseRouteInfo(
      name: interfaceType.getDisplayString(withNullability: false),
      packageURI: interfaceType.element.librarySource.uri.toString(),
      endpointsInfo: endPointsInfo,
    );
  }

  List<String> getRoutes() {
    final routes = <String>[];
    for (var e in endpointsInfo) {
      routes.add('${name.toLowerCase()}/${e.name.toLowerCase()}');
    }
    return routes;
  }

  // String get
}

class EndPointInfo {
  final String name;
  final ReturnTypeInfo returnTypeInfo;
  final ParametersInfo parametersInfo;

  EndPointInfo({
    required this.name,
    required this.returnTypeInfo,
    required this.parametersInfo,
  });

  factory EndPointInfo.fromMethodElement(MethodElement element) {
    return EndPointInfo(
      name: element.name,
      returnTypeInfo: ReturnTypeInfo.fromMethodElement(element),
      parametersInfo: ParametersInfo.fromMethodElement(element),
    );
  }
}

class ReturnTypeInfo {
  final TypeInfo typeInfo;
  ReturnTypeInfo({
    required this.typeInfo,
  });

  factory ReturnTypeInfo.fromMethodElement(MethodElement element) {
    return ReturnTypeInfo(typeInfo: TypeInfo(dartType: element.returnType));
  }
}

class ParametersInfo {
  final List<TypeInfo> typeInfo;
  ParametersInfo({
    required this.typeInfo,
  });

  factory ParametersInfo.fromMethodElement(MethodElement element) {
    final parameters = element.parameters;
    // TODO: maybe we need to pass more stuff
    return ParametersInfo(typeInfo: parameters.map((e) => TypeInfo(dartType: e.type)).toList());
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
