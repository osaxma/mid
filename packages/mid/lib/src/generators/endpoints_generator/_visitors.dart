import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '_models.dart';

class VisitEntryPointFunction extends SimpleAstVisitor {
  final String filePath;
  final List<ClassInfo> routes = [];
  VisitEntryPointFunction({required this.filePath});

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

  final List<ClassInfo> routes;

  @override
  void visitReturnStatement(ReturnStatement node) {
    // print('visiting return stateement');
    // print(node.toSource());

    // childEntities for a return statement should have three elements as follows:
    //  - the 'return' keyword
    //  - the InstanceCreation or variable
    //  - the ';' at the end.
    final endpoints = node.childEntities.toList()[1];

    // TODO(@osaxma): handle this limitation 
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

      routes.add(ClassInfo.fromInterfaceType(staticType));
    }
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    // print('visiting variable declaration ');
    // print(node.toSource());
    return super.visitVariableDeclaration(node);
  }
}
