import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:mid_auth/src/tools/random_string.dart';

const userIdClaimKey = 'user_id';
const emailClaimKey = 'email';
const metadataClaimKey = 'metadata';

// TODO: figure out if this is an appropriate way to generate a refresh token
String generateRefreshToken() => generateRandomString(25);


// this may not be needed at the server but its kept here until a client library is created
// credit: https://gist.github.com/proteye/982d9991922276ccfb011dfc55443d74
String convertJwkForRS256PublicKeyToPem(Map<String, dynamic> jwk) {
  if (jwk['kty'] != 'RSA' || jwk['alg'] != 'RS256') {
    throw Exception('The JWK does not represent a RSA256');
  }

  final exponent = _convertBase64toBigInt(jwk['e'] as String);
  final modulus = _convertBase64toBigInt(jwk['n'] as String);

  final algorithmSeq = ASN1Sequence();
  final algorithmAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList(
    [0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1],
  ));
  final paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
  algorithmSeq
    ..add(algorithmAsn1Obj)
    ..add(paramsAsn1Obj);

  final publicKeySeq = ASN1Sequence()
    ..add(ASN1Integer(modulus))
    ..add(ASN1Integer(exponent));

  final publicKeySeqBitString = ASN1BitString(Uint8List.fromList(publicKeySeq.encodedBytes));

  final topLevelSeq = ASN1Sequence()
    ..add(algorithmSeq)
    ..add(publicKeySeqBitString);

  final dataBase64 = base64
      .encode(topLevelSeq.encodedBytes)
      // formatting so each line is 64 chars 
      .replaceAllMapped(RegExp('.{64}'), (match) => '${match.group(0)}\n');

  return '''-----BEGIN PUBLIC KEY-----\r\n$dataBase64\r\n-----END PUBLIC KEY-----''';
}

BigInt _convertBase64toBigInt(String value) {
  // ensure the string is a multiple of 4 and pad it on the right with an '=' sign to be a valid base64
  final extra = value.length % 4;
  if (extra != 0) {
    // ignore: parameter_assignments
    value = value.padRight(value.length + extra, '=');
  }

  final bytes = base64.decode(value);

  // ensure each converted hex number is paded on the left if it's a single digit
  final string = bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).toList().join();
  final bigInt = BigInt.parse(string, radix: 16);
  return bigInt;
}
