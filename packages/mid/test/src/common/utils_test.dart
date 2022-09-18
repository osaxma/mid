import 'package:mid/src/common/utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../helpers/ast_helpers.dart';

void main() {
  test('has from/to Map/Json methods', () async {
    final ast = await Samples.dataclass.getResolvedAST();
    final clazz = ast.libraryElement.getClass('Sample');

    if (clazz == null) {
      throw Exception("class Sample was not found in 'Samples.dataclass'");
    }

    expect(hasFromJson(clazz.thisType), true);
    expect(hasFromMap(clazz.thisType), true);
    expect(hasToJson(clazz.thisType), true);
    expect(hasToMap(clazz.thisType), true);
  });
}
