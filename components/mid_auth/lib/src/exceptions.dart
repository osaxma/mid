// todo
class AuthException implements Exception {
  /// An error message indicating what went wrong.
  final String message;

  /// An optional explanation providing more detail on what went wrong.
  final String? explanation;

  AuthException(this.message, [this.explanation]);

  @override
  String toString() {
    final buff = StringBuffer();
    buff.write('AuthException(message:$message');
    if (explanation != null) {
      buff.write('explanation: $explanation)');
    } else {
      buff.write(')');
    }

    return buff.toString();
  }
}
