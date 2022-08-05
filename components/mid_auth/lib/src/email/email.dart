


import 'package:mid_auth/mid_auth.dart';

abstract class EmailHandler {
  Future<void> sendEmailConfirmation(User user);

  Future<void> sendPasswordResetLink(User user);

  // static const x = String.fromEnvironment('name');

}
