import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'package:mid/src/common/utils.dart';
import 'package:mid_common/mid_common.dart';

// TODO: re-evaluate if these wrappers since they were created in the early prototype
//       some stuff are redundant and in many casses other part of the program needs access
//       to the types and elements from the analyzer pkg (e.g. InterfaceType or MethodElement).
//
// WIP: Cleaning up the file and removing the wrappers (maybe keep ClassInfo and change name to RouteInfo)
class ClassInfo {
  final String className;
  final String packageURI;
  final List<MethodInfo> methodInfos;

  String get routeNameForClient => '${className}Route';

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
      packageURI: interfaceType.element2.librarySource.uri.toString(),
      methodInfos: endPointsInfo,
      interfaceType: interfaceType,
    );
  }

  // List<String> getRoutes() {
  //   final routes = <String>[];
  //   for (var m in methodInfos) {
  //     routes.add(m.routeName);
  //   }
  //   return routes;
  // }
}

class MethodInfo {
  /// The name of the class where this method is
  final String className;
  final String methodName;
  final List<ArgumentInfo> argumentsInfo;

  final MethodElement methodElement;

  String get source => methodElement.source.toString();

  DartType get returnType => methodElement.returnType;

  MethodInfo({
    required this.className,
    required this.methodName,
    required this.argumentsInfo,
    required this.methodElement,
  });

  factory MethodInfo.fromMethodElement(MethodElement element, String className) {
    final argumentsInfo = <ArgumentInfo>[];
    for (final p in element.parameters) {
      argumentsInfo.add(ArgumentInfo(parameterElement: p));
    }
    return MethodInfo(
      className: className,
      methodName: element.name,
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
  final ParameterElement parameterElement;
  DartType get type => parameterElement.type;
  ArgumentInfo({
    required this.parameterElement,
  });
  String get argName => parameterElement.name;
  bool get isNamed => parameterElement.isNamed;
  bool get isRequired => parameterElement.isRequired;
  // bool get isOptional => _parameterElement.isOptional;
  bool get isPositional => parameterElement.isPositional;
  // bool get isRequiredNamed => _parameterElement.isRequiredNamed;
  // bool get isOptionalNamed => _parameterElement.isOptionalNamed;
  bool get hasDefaultValue => parameterElement.hasDefaultValue;
  String? get defaultValue => parameterElement.defaultValueCode;
}

/// Holds information about the current project
class ProjectInfo {
  /// The target project name
  final String projectName;

  /// The path to the root directory of the project
  final String projectPath;

  /// The path to the root directory of the client project
  final String clientPath;

  /// The path to the root directory of the server project
  final String serverPath;

  /// The width of the generated formatted code
  final int formatedCodeWidth;

  const ProjectInfo({
    required this.projectName,
    required this.projectPath,
    required this.clientPath,
    required this.serverPath,
    this.formatedCodeWidth = 120,
  });
}

/// Holds a generated source code and its target path
class GeneratedSource {
  /// The target path where this file should be created
  final String targetPath;

  /// The generated source code
  // should this be formatted?
  final String source;

  /// For debugging, include the generator name
  ///
  /// e.g. Client Lib Generator or Server Serializer
  final String generatorName;

  /// Additional useful debug information
  ///
  /// If it's serializer, include the serialized class name.
  /// If it's an endpoint, include the class/method name
  final String? debugInfo;

  const GeneratedSource({
    required this.targetPath,
    required this.source,
    required this.generatorName,
    this.debugInfo,
  });
}
