import 'package:analyzer/dart/element/type.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mid/src/common/types_collector.dart';
import 'package:mid/src/common/utils.dart';

import 'package:mid_common/mid_common.dart';
import 'package:mid/src/common/models.dart';
import 'package:mid/src/templates/server_templates.dart';
import 'package:mid/src/generators/serializer_common.dart';
import 'package:mid/src/templates/create.dart';

class EndPointsSourceGenerator {
  EndPointsSourceGenerator(this.routes);

  final List<ClassInfo> routes;
  final _futureOrHandlersInstances = <String>[];
  final _streamHandlersInstances = <String>[];
  final _imports = <String>{};
  final _source = StringBuffer();

  String generate() {
    _imports.clear();
    _source.clear();
    _imports.add(generateIgnoreForFile([unusedImportLint]));
    _imports.add(generatedCodeMessage);

    _addDefaultImports();
    _source.writeln(getHandlersFunction);

    int i = 0;
    for (final route in routes) {
      _generateHandler(route, i);
      i++;
    }

    _source.writeln(_generateGetFutureOrHandlersMethod());
    _source.writeln(_generateGetStreamHandlersMethod());

    final imports = _imports.join('\n');
    final source = imports + _source.toString();

    final formattedSource = DartFormatter(pageWidth: 120).format(source);

    return formattedSource;
  }

  void _addDefaultImports() {
    _imports.add(asyncImport);
    _imports.add(dartConvertImport);
    _imports.add(midPkgImport);
    _imports.add(midServerPkgImport);
    _imports.add(serializersImport);
    _imports.add(endpointsImport);
    _imports.add(collectionImport);
  }

  void _addImport(String packageURI) {
    _imports.add("import '$packageURI';");
  }

  void _generateHandler(ClassInfo route, int index) {
    _addImport(route.packageURI);
    final className = route.className;

    for (final methodInfo in route.methodInfos) {
      if (methodInfo.methodElement.returnType.isDartAsyncStream) {
        _source.writeln(_generateStreamHandler(className, methodInfo, index));
      } else {
        _source.writeln(_generateFutureOrHandler(className, methodInfo, index));
      }
    }
  }

  String _generateFutureOrHandler(String className, MethodInfo methodInfo, int index) {
    final classInstanceName = className.toLowerCase();
    final methodName = methodInfo.methodName;

    final handlerClassName = '$className${methodName.capitalizeFirst()}Handler';

    // this is for the handler instance creation
    _futureOrHandlersInstances.add('$handlerClassName(endpoints[$index] as $className)');

    final route = methodInfo.routeName;
    final assignments = _generateArgumentAssignment(methodInfo);
    final resultName = 'result';
    final methodInvocation = _generateMethodInvocation(methodInfo, classInstanceName, resultName: resultName);
    late final String responseBody;

    var type = methodInfo.returnType;

    if (type.isDartAsyncFuture || type.isDartAsyncFutureOr || type.isDartAsyncStream) {
      if (type is InterfaceType && type.typeArguments.isNotEmpty) {
        type = type.typeArguments.first;
      }
    }

    if (type.isVoid) {
      responseBody = "'ok'";
    } else {
      responseBody = serializeValue(type as InterfaceType, resultName, useToMapFromMap: false);
    }

    final isFuture = methodInfo.returnType.isDartAsyncFuture;
    final returnType = isFuture ? 'Future<String>' : 'String';
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
      
    $methodInvocation

    return json.encode($responseBody);
  }
}

''';
  }

  String _generateStreamHandler(String className, MethodInfo methodInfo, int index) {
    final classInstanceName = className.toLowerCase();
    final methodName = methodInfo.methodName;

    final handlerClassName = '$className${methodName.capitalizeFirst()}Handler';

    // this is for the handler instance creation
    _streamHandlersInstances.add('$handlerClassName(endpoints[$index] as $className)');

    final route = methodInfo.routeName;
    final assignments = _generateArgumentAssignment(methodInfo);
    final resultName = 'result';
    final methodInvocation = _generateMethodInvocation(methodInfo, classInstanceName, resultName: resultName);
    late final String responseBody;

    final type = methodInfo.returnType as InterfaceType;
    // TODO: throw an error if the user define a Stream without type argument
    if (type.typeArguments.isEmpty) {
      throw Exception('The method ${methodInfo.methodName} in $className return a Stream without a type argument '
          'Make sure to add an argument (e.g. Stream<String>)');
    }
    final innerType = type.typeArguments.first;

    responseBody = serializeValue(innerType, 'event', useToMapFromMap: false);

    return '''

class $handlerClassName extends StreamBaseHandler {
  final $className $classInstanceName;
  $handlerClassName(this.$classInstanceName);

  @override
  String get route => '$route';

  @override
  Stream<String> handler(Map<String, dynamic> map) {
    $assignments
    
    $methodInvocation

    final stream = $resultName.map((event) => $responseBody).map((event) => json.encode(event));
    return stream;
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
      final value = deserializeValue(arg.type as InterfaceType, "$mapVariableName['$name']", useToMapFromMap: false);
      final packagesURIs = getTypesImports(arg.type);
      for (var p in packagesURIs) {
        _addImport(p);
      }
      buffer.writeln("final $name = $value;");
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

    // TODO: this is not working as intended -- the type argument could be void.
    if (!methodInfo.returnType.isVoid) {
      buffer.write('final $resultName = ');
    }
    if (methodInfo.returnType.isDartAsyncFuture) {
      buffer.write('await ');
    }
    buffer.write('$classInstanceName.${methodInfo.methodName}(');

    // create variable assignments
    for (final arg in methodInfo.argumentsInfo) {
      final name = arg.argName;

      if (arg.isPositional) {
        buffer.write(name);
      } else if (arg.isNamed) {
        buffer.write('$name:$name');
      }

      buffer.write(',');
    }

    buffer.writeln(");");

    return buffer.toString();
  }

  String _generateGetFutureOrHandlersMethod() {
    final String handlers = _futureOrHandlersInstances.join(',');

    return '''
List<FutureOrBaseHandler> _getFutureOrHandlers(List<EndPoints> endpoints) {
  final handlers = <FutureOrBaseHandler>[
    $handlers
  ];

  return handlers;
}
''';
  }

  String _generateGetStreamHandlersMethod() {
    final String handlers = _streamHandlersInstances.join(',');

    return '''
List<StreamBaseHandler> _getStreamHandlers(List<EndPoints> endpoints) {
  final handlers = <StreamBaseHandler>[
    $handlers
  ];

  return handlers;
}
''';
  }
}
