// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mid/src/common/utils.dart';
import 'package:mid/src/generators/serializer_common.dart';

const _dartConvertImportUri = "dart:convert";
const _collectionImportUri = "package:collection/collection.dart";

class ClientClassesSerializer {
  /// A set of all the available non-Dart types
  ///
  /// For `mid`, this mean the types for every return statement and argument.
  // note: should we use [TypeInfo] instead?
  final Set<InterfaceType> types;

  ClientClassesSerializer({
    required this.types,
  });

  String generate() {
    final buff = StringBuffer();
    buff.writeln("import '$_dartConvertImportUri';");
    buff.writeln("import '$_collectionImportUri';");

    for (final t in types) {
      final paras =
          getGenerativeUnnamedConstructorParameters(t).where((element) => !elementHasAnnotation(element, 'serverOnly'));
      final name = t.getDisplayString(withNullability: false);
      final clazz = _DataClassGenerator(paras.toList(), name);
      buff.writeln(clazz.toSource());
    }

    final formatter = DartFormatter(pageWidth: 120);

    return formatter.format(buff.toString());
  }
}

class _DataClassGenerator {
  final List<ParameterElement> parameters;
  final String className;

  _DataClassGenerator(this.parameters, this.className);
  late final bool _needCollectionEquality;
  String toSource() {
    _needCollectionEquality = parameters.any((element) => isDartCollection(element.type));

    return _generateClass();
  }

  String _generateClass() {
    final clazz = ClassBuilder()
      ..name = className
      ..constructors = _buildConstructors()
      ..methods = buildMethods()
      ..fields = _buildFields();

    final str = clazz.build().accept(DartEmitter(useNullSafetySyntax: true));
    return str.toString();
  }

  ListBuilder<Constructor> _buildConstructors() {
    // TODO: build fromMap and fromJson factory consts
    final constructors = <Constructor>[
      buildUnnamedConstructor(),
      buildFromMapConstructor(),
      buildFromJsonConstructor(),
    ];

    return ListBuilder(constructors);
  }

  Constructor buildUnnamedConstructor() {
    return Constructor((b) {
      b
        ..optionalParameters = buildConstructorNamedParameters()
        ..constant = true;
    });
  }

  ListBuilder<Parameter> buildConstructorNamedParameters() {
    final namedParameters = <Parameter>[];
    parameters.forEach((param) {
      namedParameters.add(
        Parameter(
          (b) {
            b
              ..name = param.name
              ..named = true
              ..toThis = true
              ..required = param.isRequired;
          },
        ),
      );
    });

    if (namedParameters.isNotEmpty) {
      // a workaround to add a trailing comma by a trailing parameter with an empty name.
      // there's no method in the ConstructorBuilder to add a trailing comma nor is there one with in DartFormatter.
      namedParameters.add(Parameter((b) {
        b.name = '';
      }));
    }

    return ListBuilder(namedParameters);
  }

  Constructor buildFromMapConstructor() {
    return Constructor((b) {
      b
        ..name = 'fromMap'
        ..factory = true
        ..requiredParameters = ListBuilder<Parameter>([
          Parameter((b) {
            b
              ..name = 'map'
              ..type = refer('Map<String, dynamic>');
          })
        ])
        ..body = generateFromMapConstructorBody();
    });
  }

  Code generateFromMapConstructorBody() {
    if (parameters.isEmpty) {
      return Code('return $className();');
    }
    final body = parameters
        .map((p) => generateFromMapArgumentAndAssignmentString(p))
        .reduce((value, element) => '$value,$element');
    return Code('return $className($body,);');
  }

  String generateFromMapArgumentAndAssignmentString(ParameterElement p) {
    final arg = p.name;
    final assignment = deserializeValue(p.type as InterfaceType, "map['$arg']", useToMapFromMap: true);
    return "$arg:$assignment";
  }

  Constructor buildFromJsonConstructor() {
    return Constructor((b) {
      b
        ..name = 'fromJson'
        ..factory = true
        ..requiredParameters = ListBuilder<Parameter>([
          Parameter((b) {
            b
              ..name = 'source'
              ..type = refer('String');
          })
        ])
        ..lambda = true
        ..body = Code('$className.fromMap(json.decode(source))');
    });
  }

  ListBuilder<Method> buildMethods() {
    final methods = <Method>[
      generateToJsonMethod(),
      generateToMapMethod(),
      if (parameters.isNotEmpty) ...[
        generateCopyWithMethod(),
        generateEqualityOperator(),
        generateHashCodeGetter(),
        generateToStringMethod(),
      ]
    ];

    return ListBuilder(methods);
  }

  Method generateToJsonMethod() {
    return Method((b) {
      b
        ..name = 'toJson'
        ..returns = refer('String')
        ..lambda = true
        ..body = Code('json.encode(toMap())');
    });
  }

  Method generateToMapMethod() {
    return Method((b) {
      b
        ..name = 'toMap'
        ..returns = refer('Map<String, dynamic>')
        ..body = generateToMapMethodBody();
    });
  }

  Code generateToMapMethodBody() {
    if (parameters.isEmpty) {
      return Code('return {};');
    }
    final body = parameters.map((p) => generateMapKeyValue(p)).reduce((value, element) => '$value,$element');
    return Code('return {$body,};');
  }

  String generateMapKeyValue(ParameterElement p) {
    final key = p.name;
    final value = serializeValue(p.type as InterfaceType, key, useToMapFromMap: true);
    return "'$key':$value";
  }

  Method generateCopyWithMethod() {
    final copyWithMethod = Method((b) {
      b
        ..returns = refer(className)
        ..name = 'copyWith'
        ..body = generateCopyWithBody()
        ..optionalParameters = generateCopyWithMethodParameters();
    });

    return copyWithMethod;
  }

  ListBuilder<Parameter> generateCopyWithMethodParameters() {
    final paras = <Parameter>[];

    paras.addAll(
      parameters.map(
        (p) {
          var type = p.type.getDisplayString(withNullability: true);
          if (!type.endsWith('?')) {
            type = '$type?';
          }
          return Parameter(
            (b) {
              b
                ..name = p.name
                ..named = true
                ..type = refer(type);
            },
          );
        },
      ),
    );

    if (paras.isNotEmpty) {
      // to force adding a trailing comma
      paras.add(Parameter((b) => b.name = ''));
    }

    return ListBuilder(paras);
  }

  Code generateCopyWithBody() {
    final body =
        parameters.map((p) => '${p.name}: ${p.name} ?? this.${p.name}').reduce((value, element) => '$value,$element');
    return Code('return $className($body,);');
  }

  Method generateEqualityOperator() {
    return Method((b) {
      b
        ..name = '=='
        ..returns = refer('bool operator')
        ..requiredParameters = ListBuilder([
          Parameter((b) {
            b
              ..name = 'other'
              ..type = refer('Object');
          })
        ])
        ..annotations = overrideAnnotation()
        ..body = generateEqualityOperatorBody();
    });
  }

  Code generateEqualityOperatorBody() {
    final fields = parameters.map((p) {
      if (isDartCollection(p.type)) {
        return 'collectionEquals(other.${p.name}, ${p.name})';
      } else {
        return 'other.${p.name} == ${p.name}';
      }
    }).reduce((prev, next) => '$prev&&$next');

    final collectionEquality =
        _needCollectionEquality ? 'final collectionEquals = const DeepCollectionEquality().equals;' : '';

    return Code('''
  if (identical(this, other)) return true;
  $collectionEquality

  return other is $className && $fields;
  ''');
  }

  Method generateHashCodeGetter() {
    final fields = parameters.map((p) => '${p.name}.hashCode').reduce((prev, next) => '$prev^$next');
    return Method((b) {
      b
        ..name = 'hashCode'
        ..type = MethodType.getter
        ..returns = refer('int')
        ..annotations = overrideAnnotation()
        ..body = Code('return $fields;');
    });
  }

  ListBuilder<Field> _buildFields() {
    final fields = <Field>[];
    for (var param in parameters) {
      fields.add(
        Field(
          (b) {
            b
              ..name = param.name
              ..modifier = FieldModifier.final$
              ..type = refer(param.type.getDisplayString(withNullability: true));
          },
        ),
      );
    }

    return ListBuilder(fields);
  }

  Method generateToStringMethod() {
    final fields = parameters.map((p) => '${p.name}: \$${p.name}').reduce((prev, next) => '$prev, $next');
    return Method((b) {
      b
        ..name = 'toString'
        ..returns = refer('String')
        ..annotations = overrideAnnotation()
        ..body = Code("return '$className($fields)';");
    });
  }

  ListBuilder<Expression> overrideAnnotation() {
    return ListBuilder(const [CodeExpression(Code('override'))]);
  }
}
