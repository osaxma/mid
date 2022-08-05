import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '_models.dart';

class VisitEndPointsFunction extends SimpleAstVisitor {
  final String filePath;
  final List<BaseRouteInfo> routes = [];
  VisitEndPointsFunction({required this.filePath});

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.name == 'entryPoint') {
      node.visitChildren(VisitReturnStatement(filePath: filePath, routes: routes));
    }
    return super.visitFunctionDeclaration(node);
  }
}

class VisitReturnStatement extends RecursiveAstVisitor {
  final String filePath;

  VisitReturnStatement({required this.filePath, required this.routes});

  final List<BaseRouteInfo> routes;

  @override
  void visitReturnStatement(ReturnStatement node) {
    // print('visiting return stateement');
    // print(node.toSource());

    // childEntities for a return statement should have three elements as follows:
    //  - the 'return' keyword
    //  - the InstanceCreation or variable
    //  - the ';' at the end.
    final endpoints = node.childEntities.toList()[1];

    if (endpoints is! ListLiteral) {
      throw Exception('The return statement for the `endpoints` function must be a list literal.\n'
          'Make sure to fix it $filePath');
    }

    for (var element in endpoints.elements) {
      if (element is! Expression) {
        // TODO: create a useful statement
        throw Exception('Uknown element in the list');
      }
      final staticType = element.staticType;
      if (staticType is! InterfaceType) {
        throw Exception('Uknown element in the list');
      }

      print('endpoint name = ${staticType.getDisplayString(withNullability: false)}');
      routes.add(BaseRouteInfo.fromInterfaceType(staticType));
      for (var method in staticType.methods) {
        if (method.isPrivate) {
          continue;
        }
        printMethodStuff(method);
      }
    }
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    // print('visiting variable declaration ');
    // print(node.toSource());
    return super.visitVariableDeclaration(node);
  }
}

void printMethodStuff(MethodElement m) {
  final name = m.name;
  final returnType = m.returnType.getDisplayString(withNullability: false);
  print(' - $name returning $returnType');
}

void printReturnTypePackageIfNotDartType(MethodElement m) {
  final type = m.returnType;

  if (isFutureOrStream(type)) {
    // handle type argument
    // final arg = type.
  }
}

bool isFutureOrStream(DartType type) => type.isDartAsyncFuture || type.isDartAsyncStream;

bool isDynamicOrObject(DartType type) => type.isDynamic || type.isDartCoreObject;

bool isBasicDartType(DartType type) =>
    type.isVoid ||
    type.isDartCoreBool ||
    type.isDartCoreDouble ||
    type.isDartCoreFunction ||
    type.isDartCoreInt ||
    type.isDartCoreNull ||
    type.isDartCoreNum ||
    type.isDartCoreObject ||
    type.isDartCoreString;

bool isIterable(DartType type) =>
    type.isDartCoreIterable || type.isDartCoreList || type.isDartCoreMap || type.isDartCoreSet;

bool isSerializable(DartType type) {
  // this should check if the type has toJson method and fromJson factory constructor
  // note: toJson and fromJson can be defined differently:
  //       1- 'String toJson()' returning json string and 'Type.fromJson(String jsonString)'
  //       2- 'Map<String, dynamic> toJson()' and 'Type.fromJson(Map<String, dynamic>)'
  //
  // we could stick with one or the other. Or handle both. In case two, we need to include the code for
  // encoding/decoding the jsonString. Also, we could look for 'fromMap' and 'toMap'
  throw UnimplementedError();
}
