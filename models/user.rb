require 'sqlite3'

class User

attr_accessor = :username, :expires
  @db = SQLite3::Database.new "chatter.db"
  @db.results_as_hash = true
  @db.type_translation = true

  def initialize(values)
    @id = values['id']
    @username = values['username']
    @name = values['name']
    @avatar_url = values['avatar_url']
    @token = values['token']
    @expires = values['expires']
    @is_admin = values['is_admin']
    @is_deleted = values['is_deleted']
    @created_at = values['created_at']
    @updated_at = values['updated_at']
  end

  def self.auth(token)
    return false unless token
    sql = "SELECT * FROM users WHERE token = ? AND datetime(expires) > datetime('now') AND is_deleted <> 'true';"
    user = @db.execute(sql, token)
    return false unless user.length == 1
    self.new(user[0])
  end

  def self.auth_admin(token)
    return false unless token
    sql = "SELECT * FROM users WHERE token = ? AND datetime(expires) > datetime('now') AND is_deleted <> 'true' AND is_admin = 'true';"
    user = @db.execute(sql, token)
    return false unless user.length == 1
    self.new(user[0])
  end

  def self.auth_for(token, user_id)
    return false unless token && user_id
    sql = "SELECT * FROM users WHERE token = ? AND id = ? AND datetime(expires) > datetime('now') AND is_deleted <> 'true';"
    user = @db.execute(sql, [token, user_id])
    return false unless user.length == 1
    self.new(user[0])
  end

  def self.all
    @db.execute "SELECT * FROM users WHERE is_deleted <> 'true';"
  end

  def to_hash
    {
      'id' => @id,
      'username' => @username,
      'name' => @name,
      'avatar_url' => @avatar_url,
      'token' => @token,
      'expires' => @expires,
      'is_admin' => @is_admin,
      'is_deleted' => @is_deleted,
      'created_at' => @created_at,
      'updated_at' => @updated_at
    }
  end
  
  def to_json
    self.to_hash.to_s
  end
end
