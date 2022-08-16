import 'package:mid_auth/mid_auth.dart';

/// WIP
abstract class EmailHandler {
  /// Sends an instruction email to the given [user] to confirm their email address
  Future<void> sendEmailConfirmationInstruction(User user);

  /// Sends an instruction email to the given [user] to reset their password 
  Future<void> sendPasswordResetInstruction(User user);
}
