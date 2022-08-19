import 'package:analyzer/dart/element/type.dart';
import 'package:dart_style/dart_style.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:mid/src/common/models.dart';
import 'package:mid/src/generators/serializer_common.dart';
import 'package:mid/src/templates/create.dart';

class ClientEndPointGenerator {
  final ClassInfo classInfo;

  final emitter = DartEmitter(useNullSafetySyntax: true);

  ClientEndPointGenerator(
    this.classInfo,
  );

  /// returns the source code for the generated client class
  String generate() {
    final methods = <Method>[];
    for (var m in classInfo.methodInfos) {
      if (m.returnType.isDartAsyncStream) {
        methods.add(_generateStreamMethod(m));
      } else {
        methods.add(_generateFutureMethod(m));
      }
    }

    final clazz = ClassBuilder()
      ..name = classInfo.classNameForClient
      ..fields = _generateClassFields()
      ..constructors = _generateConstructors()
      ..methods = ListBuilder(methods);

    final lib = Library((b) {
      b.body.addAll([
        Code(generateIgnoreForFile([unusedImportLint, unusedFieldLint])),
        // must be added to avoid an error 
        Code('\n'),
        Directive.import('package:mid_client/mid_client.dart'),
        Directive.import('../models.dart'),
        clazz.build(),
      ]);
    });

    final source = lib.accept(emitter).toString();

    return DartFormatter(pageWidth: 120).format(source);
  }

  ListBuilder<Field> _generateClassFields() {
    final fields = <Field>[
      Field(
        (b) {
          b.name = '_httpExecute';
          b.modifier = FieldModifier.final$;
          b.type = refer('Execute<Future<dynamic>>');
        },
      ),
      Field(
        (b) {
          b.name = '_streamExecute';
          b.modifier = FieldModifier.final$;
          b.type = refer('Execute<Stream<dynamic>>');
        },
      ),
    ];

    return ListBuilder(fields);
  }

  ListBuilder<Constructor> _generateConstructors() {
    return ListBuilder([
      Constructor((b) {
        b.requiredParameters = ListBuilder(
          [
            Parameter(
              (b) {
                b.name = '_httpExecute';
                b.toThis = true;
              },
            ),
            Parameter(
              (b) {
                b.name = '_streamExecute';
                b.toThis = true;
              },
            ),
          ],
        );
      })
    ]);
  }

  Method _generateFutureMethod(MethodInfo methodInfo) {
    final returnType = _ensureReturnTypeHasFuture(methodInfo.returnType);
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

  Method _generateStreamMethod(MethodInfo methodInfo) {
    final returnType = methodInfo.returnType.getDisplayString(withNullability: true);
    final m = MethodBuilder();
    m
      ..name = methodInfo.methodName
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
    var returnType = method.returnType;

    if (returnType.isDartAsyncFuture || returnType.isDartAsyncFutureOr) {
      if (returnType is InterfaceType && returnType.typeArguments.isNotEmpty) {
        returnType = returnType.typeArguments.first;
      }
    }

    late final String returnStatement;
    late final String dataAssignment;
    if (returnType.isVoid) {
      dataAssignment = 'await _httpExecute(\$args, \$route);';
      returnStatement = '';
    } else if (returnType.isDartAsyncStream) {
      dataAssignment = 'final \$data = _streamExecute(\$args, \$route);';
      final innerType = (method.returnType as InterfaceType).typeArguments.first;
      final deserializedValue = deserializeValue(innerType, 'event', useToMapFromMap: true);
      returnStatement = '\$data.map((event) => $deserializedValue)';
    } else {
      dataAssignment = 'final \$data = await _httpExecute(\$args, \$route);';
      returnStatement = deserializeValue(returnType, '\$data', useToMapFromMap: true);
    }

    // note the `$` prefix was added at the end of each variable to avoid naming conflicts with method arguments
    return Code('''
  final \$args = <String, dynamic>{
    $argsToKeyValue
  };

  final \$route = '${method.routeName}';

  $dataAssignment

  return $returnStatement;
  ''');
  }

  // convert each arg to key value pair
  String _convertMethodArgsToKeyValueString(MethodInfo method) {
    final List<String> args = [];
    for (var arg in method.argumentsInfo) {
      final name = arg.argName;
      final value = serializeValue(arg.type as InterfaceType, name, useToMapFromMap: true);
      args.add("'$name':$value");
    }
    if (args.isEmpty) {
      return '';
    }
    return '${args.reduce((v, e) => '$v,\n$e')},';
  }

  ListBuilder<Expression> overrideAnnotation() {
    return ListBuilder(const [CodeExpression(Code('override'))]);
  }
}
