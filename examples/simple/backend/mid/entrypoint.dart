import 'package:mid_auth/mid_auth.dart';

Future<List<Object>> entryPoint() async {
  final authDB = AuthSqlite();
  final jwtHandler = JWTHandlerRsa256(
    jwtPrivateKey: privateKey,
    jwtPublicKey: publicKey,
    aud: 'aud',
    issuer: 'issuer',
  );

  final auth = AuthServer(authDB: authDB, jwtHandler: jwtHandler);
  return [
    auth,
  ];
}



final publicKey = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvtPgdJmf6+wTVAPAenSS
ex364uZjI3CnhDKeTqx8dac0/Y5U16f76SohiC+ub/mX25+Tn9brazJ7C8wZZGsb
1SPxdv7oK+JmeYCk5xi/fv23pftKh5H7ZDeJ+t6GL9Mhh2GVkand9945Qs+qWUhu
C/JW+of4aJDw8q2RdAXQDlZt0AEVnAyNkFOS/2vQFfCCu/OhPL3fN11/VN9VtJZl
SRZCP0GcrfxRCDFlkHNgfpL1DWbThgV0PBV3AfqwhQDQOSFwmNB4RsSB2V1AZZAj
Huc5g3rMbl7QDaTeLv02QnXqcJ5UcNN4oRYCS5WHxuyIGW6J9IyTkfgXoRCC8A1j
hQIDAQAB
-----END PUBLIC KEY-----''';


final privateKey = '''-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAvtPgdJmf6+wTVAPAenSSex364uZjI3CnhDKeTqx8dac0/Y5U
16f76SohiC+ub/mX25+Tn9brazJ7C8wZZGsb1SPxdv7oK+JmeYCk5xi/fv23pftK
h5H7ZDeJ+t6GL9Mhh2GVkand9945Qs+qWUhuC/JW+of4aJDw8q2RdAXQDlZt0AEV
nAyNkFOS/2vQFfCCu/OhPL3fN11/VN9VtJZlSRZCP0GcrfxRCDFlkHNgfpL1DWbT
hgV0PBV3AfqwhQDQOSFwmNB4RsSB2V1AZZAjHuc5g3rMbl7QDaTeLv02QnXqcJ5U
cNN4oRYCS5WHxuyIGW6J9IyTkfgXoRCC8A1jhQIDAQABAoIBAQC1GXcGsVToHR8q
uHTOwhrR5N3YwDSNybfw6ej7WQ60yX6ss4spLy8PVQCFslqlwgWwVH1RUDIThdDo
nUXr2wqK+JWMDNZh73a5ELFu8DmsVzUWvKk6h/xAW8UC5HQMpx5G0QGVP9R8C9Xj
5hkQqoBlrhOFp8zDz+obJUXJCkstjor3Zi17AuX7vN1ysG6bio947YSAYxVo8fl9
BtigGC78ca/cr5+jglvhOxlBwnrauQc6VGuwMnSmPuKNZtuKxHmC0PmftpC7ps6k
BmaJqNzzKYeozQ51kh5CO+e5PfvViHudIDIHcEkyN5ro1bE9a/nynzrDq88fURMQ
IvqkneXxAoGBAPSC66UVT9TzhTnVzX10CoJuqRAEgNyyHipFzMy0ks0yq1yMJmks
9K7g1THYir831aYsC2kHeIS6mi1d1KCfcqioJM4CdlEXsYv//UP0a4+xfQp7uCUB
EsLQI/KwL1jPFMW3NQKIL7hqoNLKJHqMISt9gzitu63+6PG5DF8P3+ijAoGBAMfL
OhGKRoFEEcOJ8Sop77PcfeV5mjjaEqe6qODbVCgYp2bI4+4P5ZrLxlG6l+un9dqt
8PNwpWGZVwfM15LteXVDZdrw52FPNr5rW5AsheaalP7DthyGb3NAECY8BNFVys4i
DtIEa+btCobQFopC9J+TAd4ZMy0EBLdtZlZB5/23AoGBAM71wd+Jmnj1Zt79SWHW
xs6APDmCllA3s7C0RBVBAsENEl7Tge+kTbd4Nvxp/Ya9C+oLfdz4pdoy2C1uLnuG
etam/AAjtWIOXAnUM9tBF4oZAW3OKp+nuOmMo+DXoDvbjAmOeSAbhcji+B1zXE0e
LzVQl7Fx3Fn6WdHAf+g2159hAoGATHt/vzcvxkxIgJJNv9ZN7Ix7pVznrNvOSGcs
Pue3T6Igczh0CK4NNzTKtn63qX6inxP3KTn2FWad6l6AJ77AwCMM2sNdz+KDEmIG
qypgF+cVInHJRSIxh+z+QaS4M2qkOETRZ5RJuh0D6pe+CS+YdX3ROTRsYs8m/xDi
HCMerAECgYEA0yGevtYoCLW+38Uz5Hvrn/F5U2C7ssDJqFdanSHqLGkbmNHPKMZq
svlxykObKHTFbpfQXUdUJNktOeUK7nrjujvFC3IWzKox/ctZPPJP6WdnytzGMl3G
u/UVqw5L71D/7iiMbetHvvd6vLMAD13XxiRSM4J+mvAv/sE4+BVu0yY=
-----END RSA PRIVATE KEY-----''';