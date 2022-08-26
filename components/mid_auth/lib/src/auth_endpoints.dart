import 'package:mid_auth/mid_auth.dart';
import 'package:mid_auth/src/email/email.dart';
import 'package:mid_auth/src/tools/hashing.dart';
import 'package:mid/mid.dart';

/// A simple and composable Authentication API
class Auth extends EndPoints {
  /// Called to validate the email format when creating an account only
  ///
  /// When the callback returns `true`, then the process is continued.
  /// When it return `false`, then an [AuthException] is thrown.
  final bool Function(String email)? emailFormatValidator;

  /// Used to validate the password format when creating an account only
  ///
  /// When the callback returns `true`, then the process is continued.
  /// When it return `false`, then an [AuthException] is thrown.
  final bool Function(String email)? passwordFormatValidator;

  final AuthDB _authDB;
  final JWTHandler _jwtHandler;
  final EmailHandler? _emailHandler;

  /// Creates an authentication API
  ///
  /// [authDB] is used to persist the data. One can provide their own
  /// implementation or can use the existing [AuthDbSqlite] implementation.
  ///
  /// [jwtHandler] is the [JWTHandler] used to generate and validate the
  /// jwt tokens. One can provide their own implementation or use the existing
  /// [JWTHandlerRS256] one.
  ///
  /// [emailFormatValidator] and [passwordFormatValidator] are callbacks that
  /// are used to verify the format of email and password respectively when
  /// the [createUserWithEmailAndPassword] is invoked only.
  ///
  /// The [emailHandler] is used for sending the email conformation instruction, or
  /// the password reset instructions. One needs to create their own implementation.
  /// When [emailHandler] is not provided, then all invokation to methods related to
  /// email confirmation or password resets will be fail silently.
  Auth({
    required AuthDB authDB,
    required JWTHandler jwtHandler,
    EmailHandler? emailHandler,
    this.emailFormatValidator,
    this.passwordFormatValidator,
  })  : _authDB = authDB,
        _jwtHandler = jwtHandler,
        _emailHandler = emailHandler;

  Future<Session> createUserWithEmailAndPassword(String email, String password) async {
    if (!_isValidEmailAndPassword(email, password)) {
      throw AuthException('Email or Password has bad format');
    }

    final hashedPassword = hashPasswordByDBcrypt(password);

    final user = await _authDB.createUser(email, hashedPassword);

    return _createSession(user);
  }

  Future<Session> signInWithEmailAndPassword(String email, String password) async {
    final hashedPassword = await _authDB.getHashedPasswordByEmail(email);
    if (!verifyDBcryptPassword(password, hashedPassword)) {
      throw AuthException('email or password is incorrect');
    }

    final user = await _authDB.getUserByEmail(email);

    return _createSession(user);
  }

  /// This will revoke the refresh token of the current session only
  ///
  /// This method is called when a user decides to sign out from one device only, for instance.
  ///
  /// The JWT will still be valid until it expires.
  Future<void> signOut(Session session) async {
    if (!_jwtHandler.hasValidSignature(session.accessToken)) {
      throw AuthException('Invalid JWT');
    }
    final userID = _jwtHandler.getUserId(session.accessToken);
    await _authDB.revokeRefreshToken(userID, session.refreshToken);
  }

  /// This will revoke all the refresh tokens for the given user
  ///
  /// This method is called when a user decides to sign out from all devices, for instance.
  ///
  /// The JWT will still be valid until it expires.
  Future<void> signOutAll(Session session) async {
    if (!_jwtHandler.hasValidSignature(session.accessToken)) {
      throw AuthException('Invalid JWT');
    }
    final userID = _jwtHandler.getUserId(session.accessToken);
    await _authDB.revokeAllRefreshTokens(userID);
  }

  Future<Session> _createSession(User user, [String? parentRefreshToken]) async {
    final session = _jwtHandler.generate(user);
    // the refreshtoken must be persisted before returning the session
    // otherwise there would be no way to recover the session later.
    await _authDB.persistRefreshToken(session, parentRefreshToken);
    return session;
  }

  /// Creates a new session after validating the jwt and refresh token
  ///
  /// This will revoke the refresh token used to refresh the session
  Future<Session> refreshSession(Session session) async {
    if (!_jwtHandler.hasValidSignature(session.accessToken)) {
      throw AuthException('Invalid JWT');
    }

    final userID = _jwtHandler.getUserId(session.accessToken);
    final isValid = await _authDB.isRefreshTokenValid(userID, session.refreshToken);
    if (!isValid) {
      throw AuthException('Invalid Refresh Token');
    }
    // revoke the old refresh token
    await _authDB.revokeRefreshToken(userID, session.refreshToken);

    final user = await _authDB.getUserByID(userID);
    return _createSession(user, session.refreshToken);
  }

  Future<void> sendConfirmationEmail(User user) async {
    // note: should this throw if no EmailHandler was provided?
    await _emailHandler?.sendEmailConfirmationInstruction(user);
  }

  Future<Object> confirmEmail(Object object) {
    throw UnimplementedError();
  }

  Future<Object> requestPasswordReset(String email) async {
    throw UnimplementedError();
  }

  Future<Object> changePassword(String jwt, String oldPassword, String newPassword) async {
    throw UnimplementedError();
  }

  bool _isValidEmailAndPassword(String email, String password) {
    bool validEmail;
    if (emailFormatValidator != null) {
      validEmail = emailFormatValidator!(email);
    } else {
      validEmail = true;
    }

    bool validPassword;
    if (passwordFormatValidator != null) {
      validPassword = passwordFormatValidator!(email);
    } else {
      validPassword = true;
    }

    return validEmail && validPassword;
  }

  /// Returns the Public JSON Web Key (JWK) for verifying the JWT
  Map<String, dynamic> getPublicJWK() {
    if (_jwtHandler is JWTHandlerRS256) {
      return (_jwtHandler as JWTHandlerRS256).getPublicJWK();
    }

    return {};
  }

  /// Returns the public key in PEM format when the [JWTHandler] is [JWTHandlerRS256] is used.
  String getPublicKeyInPemFormat() {
    if (_jwtHandler is JWTHandlerRS256) {
      return (_jwtHandler as JWTHandlerRS256).jwtPublicKey;
    }
    return '';
  }
}
