// TODO: change the methods to:
//        - toPascalCase
//        - toSnakeCase
//        - toCamelCase
//  where each has to determine what's the current string is
extension StringUtils on String {
  String capitalizeFirst() => '${this[0].toUpperCase()}${substring(1)}';
  String lowerFirst() => '${this[0].toLowerCase()}${substring(1)}';

  /// this will remove extra spaces (i.e., > 1 space in sequence);
  String removeExtraSpace() => replaceAll(RegExp(r'\s{2,}'), ' ');

  /// Converts snake_case to camelCase
  String toCamelCaseFromSnakeCase() {
    if (!contains('_')) return this;

    return split('_').reduce((value, element) => value + element.capitalizeFirst());
  }

  /// Converts snake_case to PascalCase
  String toPascalCaseFromSnakeCase() {
    if (!contains('_')) return capitalizeFirst();

    return toCamelCaseFromSnakeCase().capitalizeFirst();
  }

  // convert PascalCase to snake_case
  String toSnakeCaseFromPascalCase() {
    // credit: https://stackoverflow.com/a/19533226/10976714
    final exp = RegExp('[A-Z]([A-Z](?![a-z]))*');
    final newString = replaceAllMapped(exp, (Match m) => ('_${m.group(0)}')).replaceFirst('_', '').toLowerCase();
    return newString;
  }

  // convert camelCase to snake_case
  String toSnakeCaseFromCamelCase() {
    return capitalizeFirst().toSnakeCaseFromPascalCase();
  }

  /// trims leading whitespace
  String ltrim() {
    return replaceFirst(RegExp(r'^\s+'), '');
  }

  /// trims trailing whitespace
  String rtrim() {
    return replaceFirst(RegExp(r'\s+$'), '');
  }
}
