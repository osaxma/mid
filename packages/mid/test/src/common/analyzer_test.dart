
import 'package:mid/src/common/types_collector.dart';
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
      final types = getAllNonDartTypes(collector.routes);
      final typesNames = types.map((e) => e.getDisplayString(withNullability: false));

      expect(typesNames, equals({'ReturnData', 'Data', 'InnerData', 'DeepData'}));
    });
  });
}
