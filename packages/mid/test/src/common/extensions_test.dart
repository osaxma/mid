import 'package:mid/src/common/extensions.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('test String extension', () {
    test(' - from PascalCase to snake_case', () {
      final string = 'PascalCase'.toSnakeCaseFromPascalCase();
      final expected = 'pascal_case';
      expect(string, expected);
    });

    test(' - from IDPascalCase to id_snake_case', () {
      final string = 'IDPascalCase'.toSnakeCaseFromPascalCase();
      final expected = 'id_pascal_case';
      expect(string, expected);
    });

    test(' - from snake_case to PascalCase', () {
      final string = 'snake_case'.toPascalCaseFromSnakeCase();
      final expected = 'SnakeCase';
      expect(string, expected);
    });

    test(' - from snake_case to camelCase', () {
      final string = 'snake_case'.toCamelCaseFromSnakeCase();
      final expected = 'snakeCase';
      expect(string, expected);
    });

    test(' - from camelCase to snake_case', () {
      final string = 'camelCase'.toSnakeCaseFromCamelCase();
      final expected = 'camel_case';
      expect(string, expected);
    });

    test(' - from camelCaseID to snake_case_id', () {
      final string = 'camelCaseID'.toSnakeCaseFromCamelCase();
      final expected = 'camel_case_id';
      expect(string, expected);
    });

    test(' - from CapitalFirst to lowerFirst', () {
      final string = 'CapitalFirst'.lowerFirst();
      final expected = 'capitalFirst';
      expect(string, expected);
    });

    test(' - from lowerFirst to CapitalFirst', () {
      final string = 'lowerFirst'.capitalizeFirst();
      final expected = 'LowerFirst';
      expect(string, expected);
    });

    test(' - trim all leading whitespace', () {
      final string = '     string'.ltrim();
      final expected = 'string';
      expect(string, expected);
    });

    test(' - trim all trailing whitespace', () {
      final string = 'string     '.rtrim();
      final expected = 'string';
      expect(string, expected);
    });

    test(' - remove extra whitespace (more than two consecutive spaces)', () {
      final string = 'a  b    c   d     e    f'.removeExtraSpace();
      final expected = 'a b c d e f';
      expect(string, expected);
    });
  });
}
