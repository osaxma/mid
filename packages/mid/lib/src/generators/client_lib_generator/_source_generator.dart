import 'package:dart_style/dart_style.dart';
import 'package:mid/src/generators/endpoints_generator/_models.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';

class ClientEndPointGenerator {
  final ClassInfo classInfo;

  /// holds a Set of non-dart types in order to serialize them for the client
  ///
  /// This set is populated during generation
  final nonDartTypes = <TypeInfo>{};

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

    print(source);
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
    final returnType = _ensureReturnTypeHasFuture(methodInfo.returnTypeInfo);
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
  String _ensureReturnTypeHasFuture(TypeInfo type) {
    if (type.isFuture || type.isStream) {
      return type.getTypeName();
    }

    return 'Future<${type.getTypeName()}>';
  }

  ListBuilder<Parameter> _generateNamedParameters(MethodInfo method) {
    final paras = <Parameter>[];
    for (var p in method.argumentsInfo.where((element) => element.isNamed)) {
      paras.add(Parameter((b) {
        b.required = p.isRequired;
        b.name = p.argName;
        b.named = p.isNamed;
        b.type = refer(p.type.getTypeName());
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
        b.type = refer(p.type.getTypeName());
        if (p.hasDefaultValue) {
          b.defaultTo = Code(p.defaultValue!);
        }
      }));
    }

    return ListBuilder(paras);
  }

  Code _generateMethodBody(MethodInfo method) {
    final argsToKeyValue = _convertMethodArgsToKeyValueString(method);
    final returnStatement = method.returnTypeInfo.generateVariableAssignmentForType('data');
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
