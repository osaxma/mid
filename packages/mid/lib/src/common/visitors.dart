import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import 'models.dart';

class RoutesCollectorFromEndpointsFunction extends SimpleAstVisitor {
  /// Used to return meaningful error message
  final String filePath;
  final List<ClassInfo> routes = [];
  RoutesCollectorFromEndpointsFunction({
    required this.filePath,
  });

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name2.value() == 'getEndPoints') {
      node.visitChildren(_VisitReturnStatement(filePath: filePath, routes: routes));
    }
    return super.visitFunctionDeclaration(node);
  }
}

class _VisitReturnStatement extends RecursiveAstVisitor {
  final String filePath;

  _VisitReturnStatement({required this.filePath, required this.routes});

  final List<ClassInfo> routes;

  @override
  void visitReturnStatement(ReturnStatement node) {
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
      final classInfo = ClassInfo.fromInterfaceType(staticType);
      routes.add(classInfo);
    }
  }
}
