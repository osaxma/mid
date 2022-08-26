This package is intended to be use with the [mid][] package as a component. 

[mid]: https://pub.dev/packages/mid


For example, you can add this to your endpoints in the following manner:

- file: `<mid_project_name>/<mid_project_name>_server/lib/mid/endpoints.dart`

    ```dart
    Future<List<EndPoints>> getEndPoints() async {
      // You can implement your own JWTHandler 
      // or use the available JWTHandlerRsa256 implementation
      final JWTHandler jwtHandler = JWTHandlerRsa256(
        jwtPrivateKey: 'jwtPrivateKey',
        jwtPublicKey: 'jwtPublicKey',
        aud: 'aud',
        issuer: 'issuer',
      );

      // You can implement your own AuthDB for persistance 
      // or use the available AuthDbSqlite implementation
      final AuthDB authDB = AuthDbSqlite(dbPath: '/path/to/an/sqlite3.db');

      final EndPoints authEndpoints = Auth(
        authDB: authDB,
        jwtHandler: jwtHandler,
      );

      return [
        authEndpoints,
      ];
    }
    ```
- For key generation, see the [Key Generation Guide](https://github.com/osaxma/mid/blob/main/components/mid_auth/KEY_GENERATION.md)
- The `dbPath` could be a path to a valid sqlite database, otherwise the database will be created there. 