
import 'package:mid/src/common/utils.dart';
import 'package:mid/src/common/visitors.dart';
import 'package:test/test.dart';

import '../../helpers/ast_helpers.dart';

void main() async {
  final sample = await getResolvedSample('endpoints.dart');
  final collector = RoutesCollectorFromEndpointsFunction(filePath: '');
  sample.visitChildren(collector);

  group('functions tests', () {
    test('find all non-Dart types', () {
      // there is only one method
      final method = collector.routes.first.methodInfos.first.methodElement;
      final types = findAllNonDartTypesFromMethodElement(method);
      final typesNames = types.map((e) => e.getDisplayString(withNullability: false));

      expect({'ReturnData', 'Data', 'InnerData', 'DeepData'}, equals(typesNames));
    });
  });
}
