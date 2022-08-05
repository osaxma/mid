import 'package:mid_auth/src/models/session.dart';
import 'package:mid_auth/src/models/user_data.dart';

abstract class JWTHandler {
  /// Generate the JWT based on [User] data.
  Session generate(User user);

  /// Determine if the JWT has a valid signature
  ///
  /// This method return `true` for a valid signature even if the token is expired.
  bool hasValidSignature(String jwt);

  /// Determine if the JWT is expired
  ///
  /// This method will not check the validity of the signature
  bool isExpired(String jwt);

  /// Determine if the JWT has a valid signature and is not expired
  bool isValid(String jwt);

  int getUserId(String jwt);
}
