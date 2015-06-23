require 'sqlite3'

puts ARGV

def up
  puts 'Migrating up...'
  db = SQLite3::Database.new "chatter.db"

  db.execute <<-SQL
    CREATE TABLE messages (
      id INTEGER PRIMARY KEY,
      body TEXT,
      topic_id INTEGER,
      parent_id INTEGER,
      created_at INTEGER,
      created_by INTEGER,
      updated_at INTEGER,
      updated_by INTEGER,
      is_deleted BOOLEAN DEFAULT 'false'
    );
  SQL

  db.execute <<-SQL
    CREATE TABLE topics(
      id integer PRIMARY KEY,
      title TEXT,
      created_at INTEGER,
      created_by INTEGER,
      updated_at INTEGER,
      updated_by INTEGER,
      is_deleted BOOLEAN DEFAULT 'false'
    );
  SQL
    
  db.execute <<-SQL
    CREATE TABLE users(
      id integer PRIMARY KEY,
      name TEXT,
      username TEXT,
      avatar_url TEXT,
      token TEXT,
      expires TEXT,
      is_admin BOOLEAN DEFAULT 'false',
      is_deleted BOOLEAN DEFAULT 'false',
      created_at INTEGER,
      updated_at INTEGER
    );
  SQL
end

def down
  puts 'Migrating down...'

  db = SQLite3::Database.new "chatter.db"
  db.execute "DROP TABLE IF EXISTS messages;"
  db.execute "DROP TABLE IF EXISTS topics;"
  db.execute "DROP TABLE IF EXISTS users;"
end

if %w{up down}.include? ARGV[0]
  eval ARGV[0] 
else
  puts "Didn't recognize command '#{ARGV[0]}'.  Only 'up' and 'down' are allowed."
end

