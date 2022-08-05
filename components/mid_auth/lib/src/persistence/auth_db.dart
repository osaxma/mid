
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


  Future<User> createUser(String email, String hashedPassword);

  Future<void> persistRefreshToken(Session session, [String? parentRefreshToken]);

  Future<String> getHashedPasswordByEmail(String email);

  Future<User> getUserByEmail(String email);

  Future<User> getUserByID(int userID);

  // sign out
  Future<void> revokeRefreshToken(int userID, String refreshToken);

  Future<void> revokeAllRefreshTokens(int userID);

  Future<bool> isRefreshTokenValid(int userID, String refreshToken);

}
