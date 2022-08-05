import 'dart:convert';

import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:mid_auth/mid_auth.dart';
import 'package:mid_auth/src/jwt/common.dart';
import 'package:x509/x509.dart' as x509;

/// - [Generate RS256 Keys] TODO(@osaxma): how to generate RS256 keys
class JWTHandlerRsa256 implements JWTHandler {
  JWTHandlerRsa256({
    required String jwtPrivateKey,
    required this.jwtPublicKey,
    required this.aud,
    required this.issuer,
    this.expiresAfter = const Duration(hours: 1),
    this.keyID,
  }) : _jwtPrivateKey = jwtPrivateKey;

  final String _jwtPrivateKey;
  final String jwtPublicKey;
  final String aud;
  final String issuer;
  final Duration expiresAfter;
  final String? keyID;

  late final _privateSigner = JWTRsaSha256Signer(privateKey: _jwtPrivateKey);
  late final _publicSigner = JWTRsaSha256Signer(publicKey: jwtPublicKey);

  @override
  Session generate(User user) {
    final issuedAt = DateTime.now().toUtc();
    final expiresAt = issuedAt.add(expiresAfter);
    final builder = JWTBuilder()
      ..issuer = issuer
      ..audience = aud
      ..issuedAt = issuedAt
      ..subject = user.id.toString()
      ..expiresAt = expiresAt
      ..setClaim(emailClaimKey, user.email)
      ..setClaim(userIdClaimKey, user.id)
      ..setClaim(metadataClaimKey, user.metadata);

    final signedToken = builder.getSignedToken(_privateSigner);

    return Session(
      accessToken: signedToken.toString(),
      refreshToken: generateRefreshToken(),
      expiryTime: expiresAt,
      user: user,
    );
  }

  @override
  bool hasValidSignature(String jwt) {
    final parsedToken = JWT.parse(jwt);
    return parsedToken.verify(_publicSigner);
  }

  @override
  bool isExpired(String jwt) {
    final parsedToken = JWT.parse(jwt);
    final expiresAt = parsedToken.expiresAt;
    if (expiresAt == null) {
      throw Exception('invalid jwt token');
    }
    final hasExpired = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000).isBefore(DateTime.now().toUtc());
    return hasExpired;
  }

  @override
  bool isValid(String jwt) {
    final parsedToken = JWT.parse(jwt);
    final validator = JWTValidator(currentTime: DateTime.now().toUtc());
    final res = validator.validate(parsedToken, signer: _publicSigner);
    return res.isEmpty;
  }

  @override
  int getUserId(String jwt) {
    final parsedToken = JWT.parse(jwt);
    final id = parsedToken.claims[userIdClaimKey];
    if (id is int) {
      return id;
    } else {
      throw Exception('user_id was not found in the jwt');
    }
  }

  Map<String, dynamic> getPublicJWK() {
    final parsedKey = x509.parsePem(jwtPublicKey).first;
    if (parsedKey is x509.SubjectPublicKeyInfo) {
      final subjectPublicKey = parsedKey.subjectPublicKey;
      if (subjectPublicKey is x509.RsaPublicKey) {
        return {
          'kty': 'RSA',
          'n': _convertBigIntToBase64(subjectPublicKey.modulus),
          'e': _convertBigIntToBase64(subjectPublicKey.exponent),
          if (keyID != null) 'kid': keyID,
          'alg': 'RS256',
          'use': 'sig',
        };
      }
    }
    throw Exception('Invalid RSA Public Key');
  }
}

String _convertBigIntToBase64(BigInt value) {
  // convert to base16
  var string = value.toRadixString(16);
  // pad with leading zero if the first number is a single digit
  if (string.length % 2 != 0) {
    string = '0$string';
  }

  // convert to bytes by spliting every 2 hex-digits by a comma then convert that into a list of integers
  // representing the bytes as utf-8.
  final bytes = string
      .replaceAllMapped(RegExp('[0-9a-f]{2}'), (match) => '${match.group(0)},')
      .split(',')
      .where((string) => string.isNotEmpty)
      .map((element) => int.parse(element, radix: 16))
      .toList();

  // convert to base64 and remove '=' padding at the end if any.
  final base64 = base64Url.encode(bytes).replaceAll('=', '');
  return base64;
}
