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

