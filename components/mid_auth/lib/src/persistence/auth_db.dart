import 'package:mid_auth/src/models/session.dart';
import 'package:mid_auth/src/models/user_data.dart';

abstract class AuthDB {
  /// Initializes the database and/or establishes a connection
  ///
  /// The user is expected to call this method to verify a proper initialization
  /// as well as to catch any errors that may be tricky to catch if the process
  /// was handled within the constructor.
  // note: how to enforce such contract? Is initializing in the constructor really an issue?
  Future<void> init();

  // bool get isInitialized;

  /// Disposes any database resources.
  Future<void> dispose();

  /// Create a new user in the database
  Future<User> createUser(String email, String hashedPassword);

  /// persist the new refresh token (i.e. [Session.refreshToken] and revoke the [parentRefreshToken]
  Future<void> persistRefreshToken(Session session, [String? parentRefreshToken]);

  /// return the user password using [email]
  Future<String> getHashedPasswordByEmail(String email);

  /// returns the [User] of the given [email]
  Future<User> getUserByEmail(String email);

  /// returns the [User] of the given [userID]
  Future<User> getUserByID(int userID);

  /// revoke the given token only for the given [userID]
  ///
  /// This is equivalent to a user signing out from one device
  Future<void> revokeRefreshToken(int userID, String refreshToken);

  /// revoke all refresh tokens of the given [userID]
  ///
  /// This is equivalent to a user requesting signing out from all devices.
  Future<void> revokeAllRefreshTokens(int userID);

  /// verifies the validity of the given refresh token.
  Future<bool> isRefreshTokenValid(int userID, String refreshToken);
}
