import 'package:dbcrypt/dbcrypt.dart';

final _dBCrypt = DBCrypt();

/// Verify a plain password against its DBCrypt hash.
bool verifyDBcryptPassword(String plainPassword, String hashedPassword) {
  final isMatched = _dBCrypt.checkpw(plainPassword, hashedPassword);
  return isMatched;
}

/// Hashes the password using BCrypt algorithm.
String hashPasswordByDBcrypt(String plainPassword, [int costFactor = 10]) {
  // Note: the salt is built into the generated hash, so no need for storing it separaetly.
  //       for more info, see: https://stackoverflow.com/a/6833165/10976714
  final salt = _dBCrypt.gensaltWithRounds(costFactor);
  final hashedPassword = _dBCrypt.hashpw(plainPassword, salt);
  return hashedPassword;
}
