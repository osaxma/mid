import 'package:mid_auth/src/tools/hashing.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

final testPassword = 'theP@assword!';

void main() {
  setUp(() {
    print('settin up');
  });

  group('hashing and verifying passwords', () {
    test(('- verify hashed password success'), () {
      final hashedPassword = hashPasswordByDBcrypt(testPassword);
      final verify = verifyDBcryptPassword(testPassword, hashedPassword);

      expect(verify, true);
    });

    test(('- verify hashed password fail'), () {
      final hashedPassword = hashPasswordByDBcrypt(testPassword);
      final verify = verifyDBcryptPassword(testPassword.substring(1), hashedPassword);

      expect(verify, false);
    });
  });
}
