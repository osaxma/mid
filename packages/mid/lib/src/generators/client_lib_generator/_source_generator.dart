import 'package:analyzer/dart/element/type.dart';
import 'package:dart_style/dart_style.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:mid/src/common/models.dart';
import 'package:mid/src/generators/endpoints_generator/serializer.dart';

class ClientEndPointGenerator {
  final ClassInfo classInfo;


  final emitter = DartEmitter(useNullSafetySyntax: true);

  ClientEndPointGenerator(
    this.classInfo,
  );

  /// returns the source code for the generated client class
  Future<String> generate() async {
    final methods = <Method>[];
    for (var m in classInfo.methodInfos) {
      methods.add(_generateMethod(m));
    }

    final clazz = ClassBuilder()
      ..name = classInfo.classNameForClient
      ..fields = _generateClassFields()
      ..constructors = _generateConstructors()
      ..methods = ListBuilder(methods);

    final source = DartFormatter().format(clazz.build().accept(emitter).toString());

    return source;
  }

  ListBuilder<Field> _generateClassFields() {
    final fields = <Field>[
      Field(
        (b) {
          b.name = 'url';
          b.modifier = FieldModifier.final$;
          b.docs = ListBuilder(['/// The server URL']);
          b.type = refer('String');
        },
      ),
      // TODO@(osaxma): change to interceptors instead
      Field(
        (b) {
          b.name = 'headersProvider';
          b.docs = ListBuilder([
            '/// A function that should provide an up-to-date headers for each request',
            '///',
            '/// e.g. Bearer Authentication (token) ',
          ]);
          b.modifier = FieldModifier.final$;
          b.type = refer('Map<String, String> Function()');
        },
      ),
    ];

    return ListBuilder(fields);
  }

  ListBuilder<Constructor> _generateConstructors() {
    return ListBuilder([
      Constructor((b) {
        b.optionalParameters = ListBuilder(
          [
            Parameter(
              (b) {
                b.name = 'url';
                b.named = true;
                b.required = true;
                b.toThis = true;
              },
            ),
            Parameter(
              (b) {
                b.name = 'headersProvider';
                b.named = true;
                b.required = true;
                b.toThis = true;
              },
            ),
          ],
        );
      })
    ]);
  }

  Method _generateMethod(MethodInfo methodInfo) {
    final returnType = _ensureReturnTypeHasFuture(methodInfo.type);
    final m = MethodBuilder();
    m
      ..name = methodInfo.methodName
      ..modifier = MethodModifier.async
      // required here means positionl ¯\_(ツ)_/¯
      // see: https://github.com/dart-lang/code_builder/issues/355
      ..requiredParameters = _generatePositionalParameters(methodInfo)
      ..optionalParameters = _generateNamedParameters(methodInfo)
      ..body = _generateMethodBody(methodInfo)
      ..returns = Reference(returnType);

    return m.build();
  }

  /// if the return type on the server is not a future, it has to be a future on the client side
  String _ensureReturnTypeHasFuture(DartType type) {
    if (type.isDartAsyncFuture || type.isDartAsyncStream) {
      return type.getDisplayString(withNullability: true);
    }

    return 'Future<${type.getDisplayString(withNullability: true)}>';
  }

  ListBuilder<Parameter> _generateNamedParameters(MethodInfo method) {
    final paras = <Parameter>[];
    for (var p in method.argumentsInfo.where((element) => element.isNamed)) {
      paras.add(Parameter((b) {
        b.required = p.isRequired;
        b.name = p.argName;
        b.named = p.isNamed;
        b.type = refer(p.type.getDisplayString(withNullability: true));
        if (p.hasDefaultValue) {
          b.defaultTo = Code(p.defaultValue!);
        }
      }));
    }

    return ListBuilder(paras);
  }

  ListBuilder<Parameter> _generatePositionalParameters(MethodInfo method) {
    final paras = <Parameter>[];
    for (var p in method.argumentsInfo.where((element) => element.isPositional)) {
      paras.add(Parameter((b) {
        b.name = p.argName;
        b.type = refer(p.type.getDisplayString(withNullability: true));
        if (p.hasDefaultValue) {
          b.defaultTo = Code(p.defaultValue!);
        }
      }));
    }

    return ListBuilder(paras);
  }

  Code _generateMethodBody(MethodInfo method) {
    final argsToKeyValue = _convertMethodArgsToKeyValueString(method);
    var returnType = method.type;

    if (returnType.isDartAsyncFuture || returnType.isDartAsyncFutureOr || returnType.isDartAsyncStream) {
      if (returnType is InterfaceType && returnType.typeArguments.isNotEmpty) {
        returnType = returnType.typeArguments.first;
      }
    }

    late final String returnStatement;
    if (returnType.isVoid) {
      returnStatement = '';
    } else {
      returnStatement = deserializeValue(returnType as InterfaceType, 'data', useToMapFromMap: true);
    }

    // final returnStatement = method.returnTypeInfo.generateVariableAssignmentForType('data');
    return Code('''
  final args = {
    $argsToKeyValue
  };

  final route = '${method.routeName}';

  final body = json.encode(args);
  final headers = headersProvider();
  headers['content-type'] = 'application/json';

  final res = await http.post(
      Uri.http(url, route),
      headers: headers,
      body: body,
    );

  if (res.statusCode >= 400) {
    throw Exception(res.body);
  }

  final data = json.decode(res.body);
  return $returnStatement;
  ''');
  }

  // convert each arg to key value pair
  String _convertMethodArgsToKeyValueString(MethodInfo method) {
    final List<String> args = [];
    for (var arg in method.argumentsInfo) {
      final name = arg.argName;
      args.add("'$name':$name");
    }
    if (args.isEmpty) {
      return '';
    }
    return '${args.reduce((v, e) => '$v,\n$e')},';
  }
}
