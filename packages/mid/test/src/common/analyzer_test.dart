import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:test/scaffolding.dart';
import 'package:path/path.dart' as p;

final _sample = ''' 
class Data {
  final int id;
  final String name;
  final InnerData innerData;
  Data({
    required this.id,
    required this.name,
    required this.innerData,
  });
}

class InnerData {
  final num number;
  final MetaData metaData;
  InnerData({
    required this.number,
    required this.metaData,
  });
}

class MetaData {}
''';

class _Visitor extends SimpleAstVisitor {
  @override
  void visitClassDeclaration(ClassDeclaration node) {
    print('visiting');
    node.declaredElement;
  }
}

void main() {
  final samplePath = p.join(Directory.current.path, 'test', 'samples', 'data_class');

  group('description', () {
    test('description', () {
      final res = resolveFile2(path: samplePath);
      
      print(Directory.current); // always returns the root directory of the project
      final ast = parseString(content: _sample);
      // final e = getRe
      final visitor = _Visitor();
      ast.unit.visitChildren(visitor);
    });
  });
}
