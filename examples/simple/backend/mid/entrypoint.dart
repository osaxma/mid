import 'package:mid_auth/mid_auth.dart';

Future<List<Object>> entryPoint() async {
  final authDB = AuthSqlite();
  final jwtHandler = JWTHandlerRsa256(
    jwtPrivateKey: 'jwtPrivateKey',
    jwtPublicKey: 'jwtPublicKey',
    aud: 'aud',
    issuer: 'issuer',
  );

  final auth = AuthServer(authDB: authDB, jwtHandler: jwtHandler);
  return [
    auth,
  ];
}
