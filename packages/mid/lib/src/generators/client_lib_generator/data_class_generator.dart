import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_style/dart_style.dart'; // for formatting the generated code
import 'package:analyzer/dart/ast/ast.dart' hide Expression; // for AST types
import 'package:analyzer/dart/ast/visitor.dart'; // for building AST visitors
import 'package:built_collection/built_collection.dart'; // for buildng parts as a list (constructors, parameters, etc.)
import 'package:code_builder/code_builder.dart';
// import 'package:dfs/src/common/ast_utils.dart';
// import 'package:dfs/src/common/io_utils.dart';

class _DataClass {
  late final formatter = DartFormatter(pageWidth: 120);
  late final emitter = DartEmitter(orderDirectives: true);

  _DataClass({
    required this.clazz,
  }) {
    // TODO: handle this in _ExtractedParameter.extractParameters and add it as a property
    //       since the generator neeeds to add deepequality anyway.
    final collectionFinder = _FindCollectionVisitor();
    clazz.accept(collectionFinder);
    needCollectionEquality = collectionFinder.foundCollection;
    extractedParameters = _ExtractedParameter.extractParameters(clazz);
    buildDataClass();
  }

  final ClassDeclaration clazz;

  /// This indicates that there's an uninitialized FieldDeclaration of a collection type
  ///
  /// This is used by the _Generator to determine if it needs to include `collection` library
  /// for deepEquality
  late final bool needCollectionEquality;
  late final List<_ExtractedParameter> extractedParameters;

  final clazzBuilder = ClassBuilder();

  String toSource() {
    return clazzBuilder.build().accept(emitter).toString();
  }

/* -------------------------------------------------------------------------- */
/*                                    TODOS                                   */
/* -------------------------------------------------------------------------- */
// TODO: handle toMap/fromMap for collections with Generic Custom Types e.g. List<Employees>
// TODO: handle deep equality for collections e.g. collectionEquals(other.list, list)
// TODO: include 'dart:convert' (for json.decode/encode) in generated code when serialization is generated
// TODO: include 'package:collection/collection.dart' import when using deep equality.
// TODO: replace classes in parsed source with generated data classes and put it into a new source.
// TODO: exclude private variables, setters/getters but preserve them in generated code.
// TODO: treat initialized fields (non-const) as fields with default value (remove initialization)
//       and if the user wants to include initialized fields, they should use getters instead or const.
//       This will prevent using any sort of annotations

/* -------------------------------------------------------------------------- */
/*                                    BASE                                    */
/* -------------------------------------------------------------------------- */

  void buildDataClass() {
    // final clazzBuilder = ClassBuilder();
    clazzBuilder
      ..name = clazz.name.name
      ..docs = ListBuilder<String>(getDocComments(clazz.documentationComment))
      ..constructors = buildConstructors()
      ..fields = buildClassFields()
      ..methods = buildMethods();

    // return clazzBuilder.build();
  }

/* -------------------------------------------------------------------------- */
/*                            CONSTRUCTORS BUILDERS                           */
/* -------------------------------------------------------------------------- */
  ListBuilder<Constructor> buildConstructors() {
    // TODO: build fromMap and fromJson factory consts
    final constructors = <Constructor>[
      buildUnnamedConstructor(),
      buildFromMapConstructor(),
      buildFromJsonConstructor(),
    ];

    return ListBuilder(constructors);
  }

/* -------------------------------------------------------------------------- */
/*                            CLASS FIELDS BUILDER                            */
/* -------------------------------------------------------------------------- */
// final String name;
// final String? nickname;
// final int age;
// final double height;
// final List<String> hobbies;
  ListBuilder<Field> buildClassFields() {
    final fields = <Field>[];
    for (var param in extractedParameters) {
      final assignment = param.assignment != null ? Code(param.assignment!) : null;
      fields.add(Field((b) {
        b
          ..name = param.name
          ..modifier = FieldModifier.final$
          ..assignment = assignment
          ..docs = ListBuilder<String>(param.documentationComment)
          ..type = param.typeRef;
      }));
    }

    return ListBuilder(fields);
  }

/* -------------------------------------------------------------------------- */
/*                           CLASS METHODS BUILDERS                           */
/* -------------------------------------------------------------------------- */
  ListBuilder<Method> buildMethods() {
    final methods = <Method>[
      generateCopyWithMethod(),
      generateToJsonMethod(),
      generateToMapMethod(),
      generateEqualityOperator(),
      generateHashCodeGetter(),
      generateToStringMethod(),
    ];

    return ListBuilder(methods);
  }

/* -------------------------------------------------------------------------- */
/*                           BUILDERS IMPLEMENTATION                          */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                             DEFAULT CONSTRUCTOR                            */
/* -------------------------------------------------------------------------- */
// const Person({
//   required this.name,
//   this.nickname,
//   required this.age,
//   required this.height,
//   required this.hobbies,
// });
  Constructor buildUnnamedConstructor() {
    return Constructor((b) {
      b
        ..optionalParameters = buildConstructorNamedParameters()
        ..constant = true;
    });
  }

  ListBuilder<Parameter> buildConstructorNamedParameters() {
    final namedParameters = <Parameter>[];
    extractedParameters.forEach((param) {
      if (param.isInitialized) return;
      namedParameters.add(
        Parameter(
          (b) {
            b
              ..name = param.name
              ..named = true
              ..toThis = true
              ..required = !param.isNullable;
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

/* -------------------------------------------------------------------------- */
/*                        fromJson Factory Constructor                        */
/* -------------------------------------------------------------------------- */
// TODO: include import 'dart:convert';
//  factory Person.fromJson(String source) => Person.fromMap(json.decode(source));
  Constructor buildFromJsonConstructor() {
    final name = clazz.name.name;
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
        ..body = Code('$name.fromMap(json.decode(source))');
    });
  }

/* -------------------------------------------------------------------------- */
/*                         fromMap Factory Constructor                        */
/* -------------------------------------------------------------------------- */
// factory Person.fromMap(Map<String, dynamic> map) {
//   return Person(
//     name: map['name'],
//     nickname: map['nickname'],
//     age: map['age'].toInt(),
//     height: map['height'].toDouble(),
//     hobbies: List<String>.from(map['hobbies']),
//   );
// }
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
    final body = extractedParameters
        .where((p) => !p.isInitialized && !p.isPrivate)
        .map((p) => p.fromMapArgumentAndAssignmentString)
        .reduce((value, element) => value + ',' + element);
    return Code('return ${clazz.name.name}($body,);');
  }

/* -------------------------------------------------------------------------- */
/*                                toMap METHOD                                */
/* -------------------------------------------------------------------------- */

// Map<String, dynamic> toMap() {
//   return {
//     'name': name,
//     'nickname': nickname,
//     'age': age,
//     'height': height,
//     'hobbies': hobbies,
//   };
// }
  Method generateToMapMethod() {
    return Method((b) {
      b
        ..name = 'toMap'
        ..returns = refer('Map<String, dynamic>')
        ..body = generateToMapMethodBody();
    });
  }

  Code generateToMapMethodBody() {
    final body = extractedParameters
        .where((p) => !p.isInitialized && !p.isPrivate)
        .map((p) => p.toMapKeyAndValueString)
        .reduce((value, element) => value + ',' + element);
    return Code('return {$body,};');
  }

/* -------------------------------------------------------------------------- */
/*                               toJson() METHOD                              */
/* -------------------------------------------------------------------------- */
//  String toJson() => json.encode(toMap());
  Method generateToJsonMethod() {
    return Method((b) {
      b
        ..name = 'toJson'
        ..returns = refer('String')
        ..lambda = true
        ..body = Code('json.encode(toMap())');
    });
  }

/* -------------------------------------------------------------------------- */
/*                               copyWith METHOD                              */
/* -------------------------------------------------------------------------- */
// Person copyWith({
//   String? name,
//   String? nickname,
//   int? age,
//   double? height,
//   List<String>? hobbies,
// }) {
//   return Person(
//     name: name ?? this.name,
//     nickname: nickname ?? this.nickname,
//     age: age ?? this.age,
//     height: height ?? this.height,
//     hobbies: hobbies ?? this.hobbies,
//   );
// }
  Method generateCopyWithMethod() {
    final copyWithMethod = Method((b) {
      b
        ..returns = refer(clazz.name.name)
        ..name = 'copyWith'
        ..body = generateCopyWithBody()
        ..optionalParameters = generateCopyWithMethodParameters();
    });

    return copyWithMethod;
  }

  ListBuilder<Parameter> generateCopyWithMethodParameters() {
    final parameters = <Parameter>[];

    parameters.addAll(
      extractedParameters.where((p) => !p.isInitialized && !p.isPrivate).map(
            (p) => Parameter(
              (b) {
                b
                  ..name = p.name
                  ..named = true
                  ..type = p.typeRefAsNullable;
              },
            ),
          ),
    );

    if (parameters.isNotEmpty) {
      // to force adding a trailing comma
      parameters.add(Parameter((b) => b.name = ''));
    }

    return ListBuilder(parameters);
  }

  Code generateCopyWithBody() {
    final body = extractedParameters
        .where((p) => !p.isInitialized && !p.isPrivate)
        .map((p) => '${p.name}: ${p.name} ?? this.${p.name}')
        .reduce((value, element) => value + ',' + element);
    return Code('return ${clazz.name.name}($body,);');
  }

/* -------------------------------------------------------------------------- */
/*                           EQUALITY AND HASH CODE                           */
/* -------------------------------------------------------------------------- */
// TODO: handle collection equality
// @override
// bool operator ==(Object other) {
//   if (identical(this, other)) return true;
//   return other is Person &&
//       other.name == name &&
//       other.nickname == nickname &&
//       other.age == age &&
//       other.height == height &&
//       other.hobbies == hobbies;
// }
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
    final className = clazz.name.name;
    final fields = extractedParameters.map((p) {
      if (p.isCollection) {
        return 'collectionEquals(other.${p.name}, ${p.name})';
      } else {
        return 'other.${p.name} == ${p.name}';
      }
    }).reduce((prev, next) => prev + '&&' + next);

    final collectionEquality =
        needCollectionEquality ? 'final collectionEquals = const DeepCollectionEquality().equals;' : '';

    return Code('''
  if (identical(this, other)) return true;
  $collectionEquality

  return other is $className && $fields;
  ''');
  }

// @override
// int get hashCode {
//   return name.hashCode ^ nickname.hashCode ^ age.hashCode ^ height.hashCode ^ hobbies.hashCode;
// }
  Method generateHashCodeGetter() {
    final fields = extractedParameters.map((p) => '${p.name}.hashCode').reduce((prev, next) => prev + '^' + next);
    return Method((b) {
      b
        ..name = 'hashCode'
        ..type = MethodType.getter
        ..returns = refer('int')
        ..annotations = overrideAnnotation()
        ..body = Code('return $fields;');
    });
  }

/* -------------------------------------------------------------------------- */
/*                                  toString                                  */
/* -------------------------------------------------------------------------- */

// @override
// String toString() {
//   return 'Person(name: $name, nickname: $nickname, age: $age, height: $height, hobbies: $hobbies)';
// }
  Method generateToStringMethod() {
    final className = clazz.name.name;
    final fields =
        extractedParameters.map((p) => p.name + ': ' '\$${p.name}').reduce((prev, next) => prev + ', ' + next);
    return Method((b) {
      b
        ..name = 'toString'
        ..returns = refer('String')
        ..annotations = overrideAnnotation()
        ..body = Code("return '$className($fields)';");
    });
  }

  /* -------------------------------------------------------------------------- */
  /*                               HELPER METHODS                               */
  /* -------------------------------------------------------------------------- */

  ListBuilder<Expression> overrideAnnotation() {
    return ListBuilder(const [CodeExpression(Code('override'))]);
  }

  String generateSourceFromSingleClass(Class clazz) {
    final str = clazz.accept(emitter);
    return str.toString();
  }
}

/* -------------------------------------------------------------------------- */
/*                               HELPER CLASSES                               */
/* -------------------------------------------------------------------------- */

class _ClassesCollectorVisitor extends SimpleAstVisitor {
  final bool includeAbstract;
  _ClassesCollectorVisitor({
    this.includeAbstract = false,
  });

  // todo remove
  final _collectionFinder = _FindCollectionVisitor();

  bool get collectionExists => _collectionFinder.foundCollection;

  final classes = <ClassDeclaration>[];
  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (includeAbstract || !node.isAbstract) {
      // todo remove
      if (!_collectionFinder.foundCollection) {
        node.accept(_collectionFinder);
      }
      classes.add(node);
    }
  }

  bool dartConvertIsImported = false;
  bool collectionPackageIsImported = false;
  @override
  visitImportDirective(ImportDirective node) {
    if (dartConvertIsImported && collectionPackageIsImported) return;
    if (node.uri.stringValue.toString() == _dartConvertImportUri) {
      dartConvertIsImported = true;
    }
    if (node.uri.stringValue.toString() == _collectionImportUri) {
      collectionPackageIsImported = true;
    }
    return super.visitImportDirective(node);
  }
}

class _FindCollectionVisitor extends RecursiveAstVisitor {
  bool foundCollection = false;
  @override
  visitFieldDeclaration(FieldDeclaration node) {
    // for some reason node.fields.type.type is always null
    // (node.fields.type.type  is a DartType and has some checks like isDartCoreList etc);
    final typeName = node.fields.type?.toSource() ?? '';
    // TODO: improve this parser
    if (typeName.startsWith(collectionReg)) {
      // initialized fields aren't generated in the data class so they're not accounted for.
      if (node.fields.variables.any((element) => element.initializer == null)) {
        foundCollection = true;
      }
    }
    if (foundCollection) {
      return;
    } else {
      return super.visitFieldDeclaration(node);
    }
  }
}

class _ExtractedParameter {
  final String name;
  final bool isNullable;
  final bool isInitialized;
  final String baseType;
  final Reference typeRef;
  final String? assignment;
  final Iterable<String> documentationComment;
  final List<String> typeArgument;
  // the source full type used to create a type reference when building the field
  final String fullType;
  _ExtractedParameter({
    required this.name,
    required this.isNullable,
    required this.isInitialized,
    required this.baseType,
    required this.documentationComment, // = const <String>[],
    required this.typeArgument,
    this.assignment,
    required this.fullType,
  }) : typeRef = refer(fullType);

  Reference? get typeRefAsNullable => isNullable ? typeRef : refer(fullType + '?');

  bool get isCollection => baseType.startsWith(collectionReg);

  bool get isPrivate => name.startsWith('_');

  // TODO: handle nested type arguments List<List<Hobby>>
  //       now this only looks at the first one.
  String get toMapKeyAndValueString {
    final key = name;
    String value = name;

    // handles: hobbies.map((x) => x.toMap()).toList() // where hobbies is of type List<Hobby> or Set<Hobby>
    if (typeArgument.isNotEmpty) {
      if (collectionTypes.contains(baseType) && !basicTypes.contains(typeArgument.first)) {
        value = isNullable ? '$name?.map((x) => x.toMap())' : '$name.map((x) => x.toMap())';
      }
    }

    // handles: hobby.toMap() // where hobby is of type Hobby
    if (!collectionTypes.contains(baseType) && !basicTypes.contains(baseType)) {
      value = isNullable ? '$name?.toMap()' : '$name.toMap()';
    }

    return "'$key':$value";
  }

  // TODO: handle nested type arguments List<List<Hobby>>
  //       now this only looks at the first one.
  String get fromMapArgumentAndAssignmentString {
    final arg = name;
    String assignment = name;
    String mapKey = "map['$name']";

    switch (baseType.replaceAll('?', '')) {
      case 'num':
      case 'dynamic':
      case 'bool':
      case 'Object':
      case 'String':
        assignment = mapKey;
        break;
      case 'int':
        // - int --> map['fieldName']?.toInt()       OR     int.parse(map['fieldName'])
        assignment = isNullable ? '$mapKey?.toInt()' : '$mapKey.toInt()';
        break;
      case 'double':
        // - double --> map['fieldName']?.double()   OR     double.parse(map['fieldName'])
        // note: dart, especially when used with web, would convert double to integer (1.0 -> 1) so account for it.
        assignment = isNullable ? '$mapKey?.toDouble()' : '$mapKey.toDouble()';
        break;
      case 'List':
        // handles: List<Hobby>.from(map['hobbies']?.map((x) => Hobby.fromMap(x))),
        if (typeArgument.isNotEmpty && !basicTypes.contains(typeArgument.first)) {
          assignment = isNullable
              ? '$mapKey == null ? null : List.from($mapKey.map((x) => ${typeArgument.first}.fromMap(x)))'
              : 'List.from($mapKey?.map((x) => ${typeArgument.first}.fromMap(x)) ?? [])';
        } else {
          assignment = isNullable ? '$mapKey == null ? null : List.from($mapKey)' : 'List.from($mapKey)';
        }
        break;
      case 'Set':
        // handles: Set<Interest>.from(map['interests']?.map((x) => Interest.fromMap(x))),
        if (typeArgument.isNotEmpty && !basicTypes.contains(typeArgument.first)) {
          assignment = isNullable
              ? '$mapKey == null ? null : Set.from($mapKey.map((x) => ${typeArgument.first}.fromMap(x)))'
              : 'Set.from($mapKey.map((x) => ${typeArgument.first}.fromMap(x)))';
        } else {
          assignment = isNullable ? '$mapKey == null ? null : Set.from($mapKey)' : 'Set.from($mapKey)';
        }
        break;
      case 'Map':
        // handles: Map<String, dynamic>.from(map['addresses']),
        assignment = isNullable ? '$mapKey == null ? null : Map.from($mapKey)' : 'Map.from($mapKey)';

        break;
      default:
        // CustomType --> CustomType.fromMap(map['fieldName'])
        assignment = isNullable ? '$mapKey == null ? null : $name.from($mapKey)' : '$name.from($mapKey)';
        break;
    }
    return '$arg: $assignment';
  }

  static List<_ExtractedParameter> extractParameters(ClassDeclaration clazz) {
    final parameters = <_ExtractedParameter>[];
    for (var member in clazz.members.whereType<FieldDeclaration>()) {
      final fullType = member.fields.type?.toSource() ?? 'dynamic';
      final baseType = getBaseType(member.fields.type);
      final typeArguments = getTypeArguments(member.fields.type);
      final isNullable = baseType.contains('?');
      final documentationComment = getDocComments(member.documentationComment);

      // note: member.fields.variables is a List since once can define multiple variables within the same declaration
      //       such as: `final int x, y, z;` or `final int x = 0, y = 1, z = 3;`
      for (var variable in member.fields.variables) {
        final name = variable.name.name;
        final isInitialized = variable.initializer != null;
        final assignment = isInitialized ? variable.initializer!.toSource() : null;

        parameters.add(
          _ExtractedParameter(
            name: name,
            isNullable: isNullable,
            isInitialized: isInitialized,
            baseType: baseType,
            assignment: assignment,
            documentationComment: documentationComment,
            typeArgument: typeArguments,
            fullType: fullType,
          ),
        );
      }
    }
    return parameters;
  }
}

/* -------------------------------------------------------------------------- */
/*                                   GENERAL                                  */
/* -------------------------------------------------------------------------- */

final collectionReg = RegExp(r'List|Map|Set');

const _dartConvertImportUri = "dart:convert";
const _collectionImportUri = "package:collection/collection.dart";

Iterable<String> getDocComments(Comment? comment) {
  if (comment != null && comment.isDocumentation && comment.tokens.isNotEmpty) {
    return comment.tokens.map((t) => t.toString());
  } else {
    return const <String>[];
  }
}

String getBaseType(TypeAnnotation? type) {
  if (type == null) {
    return "dynamic";
  }

  // TODO: check if we need to handle other types such as TypedLiteral
  if (type is NamedType) {
    // This does not include the '?' so we include it manually.
    return type.name.name + (type.question == null ? '' : '?');
  }

  // this will return the entire type with '?' and typeArguments if they exist
  return type.toSource();
}

List<String> getTypeArguments(TypeAnnotation? type) {
  if (type == null) {
    return const [];
  }

  // TODO: check if we need to handle other types such as TypedLiteral
  if (type is NamedType) {
    // This does not include the '?' so we include it manually.
    final typeArguments = type.typeArguments;
    if (typeArguments != null) {
      final arguments = typeArguments.arguments;
      return arguments.map((t) => getBaseType(t)).toList();
    }
  }

  return const [];
}

const basicTypes = {
  'bool',
  'num',
  'int',
  'String',
  'double',
  'bool?',
  'num?',
  'int?',
  'String?',
  'double?',
  'dynamic',
  'Object',
  'Object?'
};

const collectionTypes = {
  'Set',
  'Map',
  'List',
  'Set?',
  'Map?',
  'List?',
};

AstNode generateASTfromSource(String string) {
  final parsedString = parseString(
    content: string,
  );

  return parsedString.unit;
}
