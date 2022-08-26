import 'package:mid_auth/src/models/session.dart';
import 'package:mid_auth/src/models/user_data.dart';

/// A Handler for generating and validating JWT produced by the server
///
/// [JWTHandlerRsa256] is an implementation that can be used directly.
/// instead of implementing your own.
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

  /// Return the user id from the JWT claims
  // note: should this be nullable?
  int getUserId(String jwt);

  /// Returns the Public JSON Web Key (JWK) for verifying the JWT
  ///
  /// This is not intended to return JWK for private keys and hence the
  /// method explicitly state `getPublicJWK`. Therefore, this only applies
  /// to asymmetric encryption (e.g. RSA) where the public key can be used
  /// to verify the JWT by 3rd parties. On the other hand, symmetric encryption
  /// such as HMAC (e.g. HS256), requires the secret key to verify the signature.
  ///
  /// Typically, the JWK is kept at a public endpoint so 3rd party APIs can retrieve
  /// the key for verifying JWT produced by the server.
  ///
  /// References:
  /// - [RFC7517 JSON Web Key by IETF](https://datatracker.ietf.org/doc/html/rfc7517)
  /// - [Navigating RS256 and JWKS by Auth0](https://auth0.com/blog/navigating-rs256-and-jwks/)
  /// - [RS256 vs HS256 in SO](https://stackoverflow.com/a/39239395/10976714)
  /// - [JWKs manual creator](https://russelldavies.github.io/jwk-creator/)
  /// - [Googles JWK endpoint example](https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com)
  Map<String, dynamic> getPublicJWK() => const {};
}
