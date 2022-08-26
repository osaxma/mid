import 'package:mid_auth/src/models/session.dart';
import 'package:mid_auth/src/models/user_data.dart';
import 'package:mid_auth/src/persistence/auth_db.dart';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

// TODO(osaxma): handle error messages properly so they do not contain the entire query when returned to the user.
//               during debug, the entire query of createUser including the hashedPassword was returned to the client.
//               This may be unsecure. To reproduce, create an existing which will produce an error similar to the following:
/* 
  failed to decode request body Invalid argument(s): Response body "SqliteException(2067): UNIQUE constraint failed: auth_users.email, constraint failed (code 2067)
  * Connection #0 to host localhost left intact
  Causing statement: insert into auth_users (email, password) values ('example@example.com', '$2b$10$Da30XkhHwppsvpuJG3KRzeNhwo9VZt49OW7eRoq7RpU1FdgzHSTBq') RETURNING *" must be a String or a Stream.⏎
   */

// TODO(osaxma): UPDATE ALL QUERIES TO BE PARAMETERIZED

// TODO(osaxma): figure out an appropriate default path
final defaultPath = p.join(p.current, 'auth.db');

class AuthSqlite implements AuthDB {
  AuthSqlite({this.dbPath}) {
    _database = sqlite3.open(dbPath ?? defaultPath);
    init();
  }

  /// The sqlite file path
  ///
  /// if not given, <????>
  final String? dbPath;

  late final Database _database;

  @override
  Future<void> init() async {
    final numberOfAppliedMigrations = _countAppliedMigrations();
    _applyMigrations(numberOfAppliedMigrations);
  }

  @override
  Future<void> dispose() async {
    _database.dispose();
  }

  @override
  Future<User> createUser(String email, String hashedPassword) {
    final res =
        _database.select('insert into auth_users (email, password) values (?, ?) RETURNING *', [email, hashedPassword]);
    if (res.isEmpty) {
      throw Exception('could not create new user');
    }
    return Future.value(_userFromSqliteRow(res.first));
  }

  @override
  Future<String> getHashedPasswordByEmail(String email) {
    final res = _database.select('select password from auth_users where email = ? ', [email]);
    if (res.isEmpty) {
      throw Exception('User not found');
    }
    final password = res.first['password'] as String;
    return Future.value(password);
  }

  @override
  Future<User> getUserByEmail(String email) {
    final res = _database.select('select * from auth_users where email = ?', [email]);
    if (res.isEmpty) {
      throw Exception('User not found');
    }
    return Future.value(_userFromSqliteRow(res.first));
  }

  @override
  Future<User> getUserByID(int userID) {
    final res = _database.select('select * from auth_users where id = ?', [userID]);
    if (res.isEmpty) {
      throw Exception('User not found');
    }
    return Future.value(_userFromSqliteRow(res.first));
  }

  @override
  Future<void> persistRefreshToken(Session session, [String? parentRefreshToken]) async {
    if (parentRefreshToken != null) {
      _database.execute('insert into refresh_tokens (token, user_id, parent) values (?, ?, ?)',
          [session.refreshToken, session.user.id, parentRefreshToken]);
    } else {
      _database.execute(
          'insert into refresh_tokens (token, user_id) values (?, ?)', [session.refreshToken, session.user.id]);
    }
  }

  @override
  Future<void> revokeRefreshToken(int userID, String refreshToken) async {
    _database
        .execute('update refresh_tokens set revoked = true where user_id = ? and token = ?', [userID, refreshToken]);
  }

  @override
  Future<void> revokeAllRefreshTokens(int userID) async {
    _database.execute('update refresh_tokens set revoked = true where user_id = ?', [userID]);
  }

  @override
  Future<bool> isRefreshTokenValid(int userID, String refreshToken) async {
    final res =
        _database.select('select revoked from refresh_tokens where user_id = ? and token = ?', [userID, refreshToken]);
    if (res.isEmpty) {
      return false;
    }
    final revoked = res.first['revoked'];

    if (revoked is int && revoked == 0) {
      // In sqlite, boolean values are stored as integers 0 (false) and 1 (true).
      // so 0 is not revoked and 1 is revoked.
      return true;
    } else {
      return false;
    }
  }

  User _userFromSqliteRow(Row row) {
    final map = row.toTableColumnMap();
    if (map == null) {
      throw Exception('received an empty user map');
    }
    return User.fromMap(Map<String, dynamic>.from(map['auth_users']!));
  }

  int _countAppliedMigrations() {
    _createMigrationTableIfNotExist();
    final res = _database.select('select count(*) from auth_migrations');
    final row = res.rows.first;
    final version = row.first;
    if (version is int) {
      return version;
    } else {
      throw Exception('could not count the number of migrations from auth_migrations table');
    }
  }

  void _createMigrationTableIfNotExist() {
    _database.execute(
      '''
create table if not exists auth_migrations (
  id integer primary key,
  time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
    ''',
    );
  }

  void _incrementMigration() {
    _database.execute(
      '''
insert into auth_migrations default values;
    ''',
    );
  }

  void _applyMigrations(int numberOfAppliedMigrations) {
    for (final migration in _migrations.skip(numberOfAppliedMigrations)) {
      _database.execute(migration);
      _incrementMigration();
    }
  }
}

// IMPORTANT: ORDER MATTERS
// DO NOT change the order of the list
// DO ADD new migrations at the bottom of the list ONLY
List<String> _migrations = [
  '''
create table auth_users (
  id integer primary key,
  email text NOT NULL,
  password text NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  email_confirmed_at TIMESTAMP,
  email_confirmation_token text,
  email_confirmation_token_sent_at TIMESTAMP,
  password_recovery_token text,
  password_recovery_token_sent_at TIMESTAMP,
  -- note: this a json string since sqlite doesn't have a json type
  metadata text,

  -- unique case insenstive index
  UNIQUE (email COLLATE NOCASE)
);

create table refresh_tokens (
  id integer primary key,
  token text NOT NULL,	
  parent text,
  user_id integer NOT NULL,	
  revoked bool NOT NULL DEFAULT false,	
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,	
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY(user_id) REFERENCES auth_users(id) ON DELETE CASCADE
);


CREATE TRIGGER update_refresh_tokens_updated_at_trigger 
    AFTER UPDATE 
    ON refresh_tokens 
    FOR EACH ROW 
    WHEN NEW.updated_at = OLD.updated_at -- to avoid infinite loop
BEGIN  
    UPDATE refresh_tokens  
    SET updated_at = current_timestamp 
    WHERE id = old.id; 
END;

CREATE TRIGGER update_auth_users_updated_at_trigger 
    AFTER UPDATE 
    ON auth_users 
    FOR EACH ROW 
    WHEN NEW.updated_at = OLD.updated_at -- to avoid infinite loop
BEGIN  
    UPDATE auth_users  
    SET updated_at = current_timestamp 
    WHERE id = old.id; 
END;
''',
];
