import '../packages/mid/bin/mid.dart' as mid;

// A copy of packages/mid/bin/mid.dart for local development.
void main(List<String> arguments) {
  if (arguments.contains('--help')) {
    // ignore_for_file: avoid_print
    print('''
---------------------------------------------------------
| You are running a local development version of mid. |
---------------------------------------------------------
''');
  }
  mid.main(arguments);
}
