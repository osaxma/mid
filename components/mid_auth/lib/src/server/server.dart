import 'package:mid_auth/mid_auth.dart';
import 'package:mid_auth/src/email/email.dart';
import 'package:mid_auth/src/tools/hashing.dart';
import 'package:mid/mid.dart';


/// a simple authentication API
class Auth extends EndPoints {
  Auth({
    required AuthDB authDB,
    required JWTHandler jwtHandler,
    EmailHandler? emailHandler,
  })  : _authDB = authDB,
        _jwtHandler = jwtHandler,
        _emailHandler = emailHandler;

  final AuthDB _authDB;
  final JWTHandler _jwtHandler;
  final EmailHandler? _emailHandler;

  Future<Session> createUserWithEmailAndPassword(String email, String password) async {
    if (!_verifyEmailAndPasswordFormat(email, password)) {
      throw Exception('Email or Password has bad format');
    }

    final hashedPassword = hashPasswordByDBcrypt(password);

    final user = await _authDB.createUser(email, hashedPassword);

    return _createSession(user);
  }

  Future<Session> signInWithEmailAndPassword(String email, String password) async {
    final hashedPassword = await _authDB.getHashedPasswordByEmail(email);
    if (!verifyDBcryptPassword(password, hashedPassword)) {
      throw Exception('email or password is incorrect');
    }

    final user = await _authDB.getUserByEmail(email);

    return _createSession(user);
  }

  /// This will revoke the refresh token of the current session only
  ///
  /// This method is called when a user decides to sign out from one device only, for instance.
  ///
  /// The JWT will still be valid until it expires.
  Future<void> signOut(String jwt, String refreshToken) async {
    if (!_jwtHandler.hasValidSignature(jwt)) {
      throw Exception('Invalid JWT');
    }
    final userID = _jwtHandler.getUserId(jwt);
    await _authDB.revokeRefreshToken(userID, refreshToken);
  }

  /// This will revoke all the refresh tokens for the given user
  ///
  /// This method is called when a user decides to sign out from all devices, for instance.
  ///
  /// The JWT will still be valid until it expires.
  Future<void> signOutAll(String jwt) async {
    if (!_jwtHandler.hasValidSignature(jwt)) {
      throw Exception('Invalid JWT');
    }
    final userID = _jwtHandler.getUserId(jwt);
    await _authDB.revokeAllRefreshTokens(userID);
  }

  Future<Session> _createSession(User user, [String? parentRefreshToken]) async {
    final session = _jwtHandler.generate(user);
    // the refreshtoken must be persisted before returning the session
    // otherwise there would be no way to recover the session later.
    await _authDB.persistRefreshToken(session);
    return session;
  }

  /// Creates a new session after validating the jwt and refresh token
  Future<Session> refreshSession(String jwt, String refreshToken) async {
    if (!_jwtHandler.hasValidSignature(jwt)) {
      throw Exception('Invalid JWT');
    }

    final userID = _jwtHandler.getUserId(jwt);
    final isValid = await _authDB.isRefreshTokenValid(userID, refreshToken);
    if (!isValid) {
      throw Exception('Invalid Refresh Token');
    }
    // revoke the old refresh token
    await _authDB.revokeRefreshToken(userID, refreshToken);

    final user = await _authDB.getUserByID(userID);
    return _createSession(user, refreshToken);
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

  bool _verifyEmailAndPasswordFormat(String email, String password) {
    return true;
  }

  /// Returns the Public JSON Web Key (JWK) for verifying JWT produced by an RS256
  ///
  /// Since RSA is an asymmetric algorithm, the signature of the JWT can be
  /// verified using the public key by 3rd party APIs. On the other hand,
  /// symmetric algorithms such as HMAC (e.g. HS256), requires the secret key
  /// to verify the signature.
  ///
  /// Currently, this method will only return a valid JWK for [JWTHandlerRsa256].
  /// Otherwise, it'll return an empty map.
  ///
  /// Typically, the JWK is kept at a public endpoint so 3rd party APIs can retrieve
  /// the key for verifying JWT produced by this servers.
  ///
  /// References:
  /// - [RFC7517 JSON Web Key by IETF](https://datatracker.ietf.org/doc/html/rfc7517)
  /// - [Navigating RS256 and JWKS by Auth0](https://auth0.com/blog/navigating-rs256-and-jwks/)
  /// - [RS256 vs HS256 in SO](https://stackoverflow.com/a/39239395/10976714)
  /// - [JWKs manual creator](https://russelldavies.github.io/jwk-creator/)
  /// - [Googles JWK example format](https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com)
  Map<String, dynamic> getPublicJWK() {
    if (_jwtHandler is JWTHandlerRsa256) {
      return (_jwtHandler as JWTHandlerRsa256).getPublicJWK();
    }

    return {};
  }

  /// Returns the public key in PEM format when the [JWTHandler] is [JWTHandlerRsa256] is used.
  String getPublicKeyInPemFormat() {
    if (_jwtHandler is JWTHandlerRsa256) {
      return (_jwtHandler as JWTHandlerRsa256).jwtPublicKey;
    }
    return '';
  }
}
