import 'package:analyzer/dart/element/type.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mid/src/common/analyzer.dart';

import 'package:mid/src/common/extensions.dart';
import 'package:mid/src/common/models.dart';
import 'package:mid/src/generators/endpoints_generator/serializer.dart';
import 'package:mid/src/generators/endpoints_generator/templates.dart';
import 'package:mid/src/templates/init.dart';

class EndPointsSourceGenerator {
  EndPointsSourceGenerator(this.routes);

  final List<ClassInfo> routes;
  final _handlerClassesInstances = <String>[];
  final _imports = StringBuffer();
  final _source = StringBuffer();

  String generate() {
    _imports.clear();
    _source.clear();
    _imports.writeln(generatedCodeMessage);
    _imports.writeln();
    _addDefaultImports();
    _addDefaultTemplates();

    int i = 0;
    for (final route in routes) {
      _generateHandler(route, i);
      i++;
    }

    _imports.writeln();

    _source.writeln(_generateHandlersList());

    final source = _imports.toString() + _source.toString();

    final formattedSource = DartFormatter().format(source);

    return formattedSource;
  }

  void _addDefaultImports() {
    _imports.writeln(asyncImport);
    _imports.writeln(dartConvertImport);
    _imports.writeln(shelfImport);
    _imports.writeln(shelfRouterImport);
    _imports.writeln(endpointsImport);
  }

  void _addDefaultTemplates() {
    _source.writeln(generateRouterMethod);
    _source.writeln(futureOrBaseHandler);
    _source.writeln(streamBaseHandler);
  }

  void _addImport(String packageURI) {
    _imports.writeln("import '$packageURI';");
  }

  void _generateHandler(ClassInfo route, int index) {
    _addImport(route.packageURI);
    final className = route.className;

    for (final methodInfo in route.methodInfos) {
      _source.writeln(_generateHandlerClass(className, methodInfo, index));
    }
  }

  // this is for the handler instance creation
  void _addHandlerClassToListOfHandlers(String handlerName, String className, int handlerIndex) {
    _handlerClassesInstances.add('$handlerName(list[$handlerIndex] as $className)');
  }

  String _generateHandlerClass(String className, MethodInfo methodInfo, int index) {
    final classInstanceName = className.toLowerCase();
    final methodName = methodInfo.methodName;

    final handlerClassName = '$className${methodName.capitalizeFirst()}Handler';

    _addHandlerClassToListOfHandlers(handlerClassName, className, index);

    final route = methodInfo.routeName;
    final assignments = _generateArgumentAssignment(methodInfo);
    final resultName = 'result';
    final methodInvocation = _generateMethodInvocation(methodInfo, classInstanceName, resultName: resultName);
    late final String responseBody;

    var type = methodInfo.returnTypeInfo.dartType;

    if (type.isDartAsyncFuture || type.isDartAsyncFutureOr || type.isDartAsyncStream) {
      if (type is InterfaceType && type.typeArguments.isNotEmpty) {
        type = type.typeArguments.first;
      }
    }

    if (type.isVoid) {
      responseBody = "'ok'";
    } else {
      responseBody = serializeValue(type as InterfaceType, resultName);
    }

    final isFuture = methodInfo.returnTypeInfo.dartType.isDartAsyncFuture;
    final isStream = methodInfo.returnTypeInfo.dartType.isDartAsyncFuture;
    final returnType = isFuture ? 'Future<Response>' : 'Response';
    final asyncKeyWord = isFuture ? 'async' : '';

    return '''

class $handlerClassName extends FutureOrBaseHandler {
  final $className $classInstanceName;
  $handlerClassName(this.$classInstanceName);

  @override
  String get route => '$route';
  @override
  $returnType handler(Map<String, dynamic> map) $asyncKeyWord {
    $assignments
    try {
      $methodInvocation

      return Response.ok(json.encode($responseBody));
    } catch (e) {
      return Response.badRequest(body: e.toString());
    }
  }
}

''';
  }

  /// Given a `Map<String, dynamic> map`, extract each argument based on its name
  /// e.g. if the method at hand is:
  ///    Future<String> myMethod(String x, {String? y}) { .... }
  /// then the resulting source code is:
  ///    final x = map['x'] as String;
  ///    final y = map['y'] as String?;
  String _generateArgumentAssignment(MethodInfo methodInfo, {String mapVariableName = 'map'}) {
    final buffer = StringBuffer();
    for (final arg in methodInfo.argumentsInfo) {
      final name = arg.argName;
      buffer.writeln(
          "final $name = ${deserializeValue(arg.type.dartType as InterfaceType, "$mapVariableName['$name']")};");

      if (!isDartType(arg.type.dartType)) {
        final typePackageURI = getTypePackageURI(arg.type.dartType as InterfaceType);
        if (typePackageURI != null) {
          _addImport(typePackageURI);
        }
      }
    }
    return buffer.toString();
  }

  // TODO: move this to MethodInfo.generateMethodInvocation
  /// generates:
  /// final [resultName] = [classInstanceName].[methodInfo.methodName](args)
  ///
  /// e.g.
  /// final result = SomeClassInstance.Method(value1, {namedArg: value2, namedOptionalArg: value3 ?? defaultValue});
  String _generateMethodInvocation(MethodInfo methodInfo, String classInstanceName, {required String resultName}) {
    final buffer = StringBuffer();
    if (!methodInfo.returnTypeInfo.dartType.isVoid) {
      buffer.write('final $resultName = ');
    }
    if (methodInfo.returnTypeInfo.dartType.isDartAsyncFuture) {
      buffer.write('await ');
    }
    buffer.write('$classInstanceName.${methodInfo.methodName}(');

    // if there are named arguments
    bool hasOpeningCurlyBracket = false;
    // create variable assignments
    for (final arg in methodInfo.argumentsInfo) {
      final name = arg.argName;

      // the assigned value
      final value = arg.hasDefaultValue ? '$name ?? ${arg.defaultValue}' : name;

      if (arg.isPositional) {
        buffer.write(value);
      } else if (arg.isNamed) {
        if (!hasOpeningCurlyBracket) {
          hasOpeningCurlyBracket = true;
          buffer.write('{');
        }
        buffer.write('$name:$value');
      }

      buffer.write(',');
    }

    if (hasOpeningCurlyBracket) {
      buffer.write('}');
    }
    buffer.writeln(");");

    return buffer.toString();
  }

  String _generateHandlersList() {
    final String handlers = _handlerClassesInstances.join(',');

    return '''
Future<List<FutureOrBaseHandler>> getHandlers() async {
  final list = await endpoints();
  final handlers = <FutureOrBaseHandler>[
    $handlers
  ];

  return handlers;
}
''';
  }
}
