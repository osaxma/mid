import 'package:sqlite3/sqlite3.dart';

import 'tables.dart';

class SqliteMigration {
  final int id;
  final String description;
  final String statement;

  const SqliteMigration({
    required this.id,
    required this.description,
    required this.statement,
  });
}

void applyMigrations(Database database, List<SqliteMigration> migrations, {void Function(String)? logger}) {
  final ids = migrations.map((e) => e.id).toSet();
  if (ids.length != migrations.length) {
    throw Exception('A migration with duplicate id was found');
  }

  // create migration table if it does not exist:
  database.execute(_createMigrationTableIfNotExistStatement);

  // get the applied migrations ids
  final appliedMigrationsIdsResult = database.select('select id from $migrationsTable');

  final appliedMigrationsIds = appliedMigrationsIdsResult.rows.map((row) => row.first as int);

  for (var migration in migrations) {
    if (appliedMigrationsIds.contains(migration.id)) {
      continue;
    } else {
      database.execute(migration.statement);
      database.execute('insert into $migrationsTable (id) values (?)', [migration.id]);
      logger?.call('"${migration.description}" - migration (id: ${migration.id}) was executed');
    }
  }
}


/* -------------------------------------------------------------------------- */
/*                                 STATEMENTS                                 */
/* -------------------------------------------------------------------------- */

const _createMigrationTableIfNotExistStatement = '''
create table if not exists $migrationsTable (
  id integer primary key,
  time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
''';

/* -------------------------------------------------------------------------- */
/*                                 MIGRATIONS                                 */
/* -------------------------------------------------------------------------- */
// Create new migration by incrementing the id of the latest migration manually
// Once a `SqliteMigration` is created, add it to `migrations` list
// do not change the `id` of any existing migration.
// If a change needs to happen, create a new `SqliteMigration` to implement that change.

final defaultMigrations = <SqliteMigration>[
  _createUsersTableMigration,
  _createRefreshTokensTableMigration,
];


const _createUsersTableMigration = SqliteMigration(
  id: 0,
  description: 'create users table',
  statement: ''' 
create table $usersTables (
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


CREATE TRIGGER update_${usersTables}_updated_at_trigger 
    AFTER UPDATE 
    ON  $usersTables 
    FOR EACH ROW 
    WHEN NEW.updated_at = OLD.updated_at -- to avoid infinite loop
BEGIN  
    UPDATE  $usersTables  
    SET updated_at = current_timestamp 
    WHERE id = old.id; 
END;
    ''',
);

const _createRefreshTokensTableMigration = SqliteMigration(
  id: 1,
  description: 'create refresh tokens table',
  statement: '''
create table $refreshTokensTable (
  id integer primary key,
  token text NOT NULL,	
  parent text,
  user_id integer NOT NULL,	
  revoked bool NOT NULL DEFAULT false,	
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,	
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY(user_id) REFERENCES $usersTables(id) ON DELETE CASCADE
);

CREATE TRIGGER update_${refreshTokensTable}_updated_at_trigger 
    AFTER UPDATE 
    ON $refreshTokensTable 
    FOR EACH ROW 
    WHEN NEW.updated_at = OLD.updated_at -- to avoid infinite loop
BEGIN  
    UPDATE $refreshTokensTable  
    SET updated_at = current_timestamp 
    WHERE id = old.id; 
END;
''',
);
