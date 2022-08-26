import 'dart:io';

import 'package:mid_auth/mid_auth.dart';
import 'package:sqlite3/common.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:path/path.dart' as p;

import '../sample_keys.dart';

void main() {
  final email = 'example@example.com';
  final password = 'p@asword';
  final jwtExpireAfter = Duration(seconds: 123);
  late Auth auth;
  late AuthDB authDB;
  late JWTHandler jwtHandler;
  late DateTime timeNow;
  // to allow running tests separaetly
  bool wasAccountCreated = false;

  setUpAll(() {
    timeNow = DateTime.now().toUtc();
    final dbName = 'auth_${timeNow.millisecondsSinceEpoch}';
    final tempFolder = Directory.systemTemp.path;
    final dbPath = p.join(tempFolder, dbName);
    authDB = AuthDbSqlite(dbPath: dbPath);
    jwtHandler = JWTHandlerRS256(
        jwtPrivateKey: sampleRsa256PrivateKey,
        jwtPublicKey: sampleRsa256PublicKey,
        aud: 'aud',
        issuer: 'issuer',
        expiresAfter: Duration(seconds: 123));
    auth = Auth(authDB: authDB, jwtHandler: jwtHandler);
    print('db created at $dbPath');
  });

  group('AuthSqliteDB persistance with JWTRsa256Handler', () {
    // this allows running tests separetly
    setUp(() async {
      if (!wasAccountCreated) {
        await auth.createUserWithEmailAndPassword(email, password);
        wasAccountCreated = true;
      }
    });

    test('creating an account is successful', () async {
      // This is to test account creation separate from the account used by the rest of the tests.
      final email = 'example2@example.com';
      final session = await auth.createUserWithEmailAndPassword(email, password);

      expect(session.user.email, email);
      expect(session.user.id, 2); // a user with id = 1 was created by setUp already
      expect(session.user.emailConfirmedAt, null);
      expect(session.user.emailConfirmedAt, null);
      expect(jwtHandler.isValid(session.accessToken), true);
      expect(jwtHandler.isExpired(session.accessToken), false);

      expect(
        session.expiryTime.millisecondsSinceEpoch,
        lessThanOrEqualTo(
            timeNow.add(jwtExpireAfter).millisecondsSinceEpoch + 2000), // add 2 seconds for any possible delays
      );
    });

    test('create an account on existing email fails', () async {
      // This is to test account creation separate from the account used by the rest of the tests.
      try {
        await auth.signInWithEmailAndPassword(email, password);
      } catch (e) {
        expect(e, isA<SqliteException>);
      }
    });

    test('sign in with wrong password throws an exception', () async {
      try {
        await auth.signInWithEmailAndPassword(email, 'wrong-password');
      } catch (e) {
        expect(e, isA<AuthException>());
      }
    });

    test('sign in with non-existing email throws an exception', () async {
      try {
        await auth.signInWithEmailAndPassword('non-existing-email@example.com', 'no-password');
      } catch (e) {
        expect(e, isA<AuthException>());
      }
    });

    test('sign in successful with new tokens', () async {
      final session = await auth.signInWithEmailAndPassword(email, password);
      expect(session.user.email, email);
      expect(session.user.id, 1);
      expect(session.user.emailConfirmedAt, null);
      expect(session.user.emailConfirmedAt, null);
      expect(session.accessToken, isNotEmpty);
      expect(session.refreshToken, isNotEmpty);
      expect(jwtHandler.isValid(session.accessToken), true);
      expect(jwtHandler.isExpired(session.accessToken), false);
    });

    test('sign in multiple times generates new access tokens & refresh tokens', () async {
      final session1 = await auth.signInWithEmailAndPassword(email, password);
      await Future.delayed(Duration(seconds: 2)); // to allow different expiry time, hence different access token
      final session2 = await auth.signInWithEmailAndPassword(email, password);

      expect(session1.accessToken, isNot(equals(session2.accessToken)));
      expect(session1.refreshToken, isNot(equals(session2.refreshToken)));
    });

    test('sign in multiple times does not invalidate previous access tokens', () async {
      final session1 = await auth.signInWithEmailAndPassword(email, password);
      await Future.delayed(Duration(seconds: 1)); // to allow different expiry time, hence  different access token
      final session2 = await auth.signInWithEmailAndPassword(email, password);

      final isSession1RefreshTokenValid = await authDB.isRefreshTokenValid(
        session1.user.id,
        session1.refreshToken,
      );
      expect(isSession1RefreshTokenValid, true);

      final isSession2RefreshTokenValid = await authDB.isRefreshTokenValid(
        session2.user.id,
        session2.refreshToken,
      );
      expect(isSession2RefreshTokenValid, true);
    });

    test('sign out only invalides the given session refresh token', () async {
      final session1 = await auth.signInWithEmailAndPassword(email, password);
      await Future.delayed(Duration(seconds: 2)); // to allow different expiry time, hence different access token
      final session2 = await auth.signInWithEmailAndPassword(email, password);

      await auth.signOut(session1);

      final isSession1RefreshTokenValid = await authDB.isRefreshTokenValid(
        session1.user.id,
        session1.refreshToken,
      );
      expect(isSession1RefreshTokenValid, false);

      final isSession2RefreshTokenValid = await authDB.isRefreshTokenValid(
        session2.user.id,
        session2.refreshToken,
      );
      expect(isSession2RefreshTokenValid, true);
    });

    // equivalent to signing out from all devices
    test('sign out from all invalides all refresh token', () async {
      final session1 = await auth.signInWithEmailAndPassword(email, password);
      await Future.delayed(Duration(seconds: 2)); // to allow different expiry time, hence different access token
      final session2 = await auth.signInWithEmailAndPassword(email, password);

      await auth.signOutAll(session1);

      final isSession1RefreshTokenValid = await authDB.isRefreshTokenValid(
        session1.user.id,
        session1.refreshToken,
      );
      expect(isSession1RefreshTokenValid, false);

      final isSession2RefreshTokenValid = await authDB.isRefreshTokenValid(
        session2.user.id,
        session2.refreshToken,
      );
      expect(isSession2RefreshTokenValid, false);
    });

    test('refresh token invalidates previous token', () async {
      final session = await auth.signInWithEmailAndPassword(email, password);
      await Future.delayed(Duration(seconds: 2)); // to allow different expiry time, hence different access token
      final newSession = await auth.refreshSession(session);

      final isOldSessionRefreshTokenValid = await authDB.isRefreshTokenValid(
        session.user.id,
        session.refreshToken,
      );
      expect(isOldSessionRefreshTokenValid, false, reason: 'old token must be revoked');

      final isNewSessionRefreshTokenValid = await authDB.isRefreshTokenValid(
        newSession.user.id,
        newSession.refreshToken,
      );

      expect(isNewSessionRefreshTokenValid, true, reason: 'new token should be valid');
    });
  });
}
