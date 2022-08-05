// ignore: deprecated_member_use
import 'dart:cli';
import 'dart:io';
import 'dart:isolate';


// credit: https://stackoverflow.com/a/72333119/10976714
String getAsset() {
  final packageUri = Uri.parse('package:mid_auth/src/persistence/sqlite/migrations/0001_init.sql');
  final future = Isolate.resolvePackageUri(packageUri);

// waitFor is strongly discouraged in general, but it is accepted as the
// only reasonable way to load package assets outside of Flutter.
// ignore: deprecated_member_use
  final absoluteUri = waitFor(future, timeout: const Duration(seconds: 5));
  if (absoluteUri == null) {
    return '';
  }
  final file = File.fromUri(absoluteUri);
  if (file.existsSync()) {
    return file.path;
  }
  return '';
}
