import 'package:mid/src/common/utils.dart';
import 'package:mid/src/common/visitors.dart';
import 'package:test/scaffolding.dart';

import '../../../helpers/ast_helpers.dart';

void main() async {
  final sample = await getResolvedSample('endpoints.dart');
  final collector = RoutesCollectorFromEndpointsFunction(filePath: '');
  sample.visitChildren(collector);
  final method = collector.routes.first.methodInfos.first.methodElement;
  final types = findAllNonDartTypesFromMethodElement(method);

  // final serializer = ServerClassesSerializer(types: types);

  group('functions', () {
    test('all Arguments In Unnamed Constructor Is To This', () {

      // allArgumentsInUnnamedConstructorIsToThis(types.first);

    });
  });
}