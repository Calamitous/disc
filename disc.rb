require 'thin'
require 'sqlite3'
require 'sinatra'
require 'json'
require 'rpam'
require 'uuid'
require './models/user.rb'

set :bind, '0.0.0.0'
set :port, 4444

db = SQLite3::Database.new "chatter.db"
db.results_as_hash = true
# This isn't actually doing type translation, but it _is_ suppressing indexed
# copies of the data in the returned hashes, so... yay?
db.type_translation = true


# *** MESSAGES ***
get '/messages.json' do
  messages = db.execute "
    SELECT *
    FROM messages m
      INNER JOIN topics t ON t.id = m.topic_id
    WHERE m.is_deleted <> 'true'
      AND t.is_deleted <> 'true';"
  messages.to_json
end

get '/messages/:id.json' do
  messages = db.execute "
    SELECT *
    FROM messages m
      INNER JOIN topics t ON t.id = m.topic_id
    WHERE id = ?
      AND m.is_deleted <> 'true'
      AND t.is_deleted <> 'true'
    LIMIT 1;", params[:id]
  messages[0].to_json
end

delete '/messages/:id' do
  db.execute "UPDATE messages SET is_deleted = 'true' WHERE id = ? AND is_deleted <> 'true';", params[:id]
  status 200
end

post '/messages/new' do
  db.execute(
    "INSERT INTO messages (body, parent_id, topic_id) VALUES (?, ?, ?);",
    [params[:body], params[:parent_id], params[:topic_id]])
  status 200
end

# *** TOPICS ***
get '/topics.json' do
  topics = db.execute "SELECT * FROM topics WHERE is_deleted <> 'true';"
  topics.to_json
end

get '/topics/:id.json' do
  topics = db.execute "SELECT * FROM topics WHERE id = ? AND is_deleted <> 'true' LIMIT 1;", params[:id]
  topics[0].to_json
end

delete '/topics/:id' do
  db.execute "UPDATE topics SET is_deleted = 'true' WHERE id = ? AND is_deleted <> 'true';", params[:id]
  status 200
end

post '/topics/new' do
  db.execute("INSERT INTO topics (title) VALUES (?);", params[:title])
  status 200
end

# *** USERS ***
get '/users.json' do
  unless User.auth_admin params[:token]
    status 401
    return
  end

  User.all.to_json
end

get '/users/:id.json' do
  unless user = User.auth_for(params[:token], params[:id])
    status 401
    return
  end

  user.to_json
end

delete '/users/:id' do
  db.execute "UPDATE users SET is_deleted = 'true' WHERE id = ? AND is_deleted <> 'true';", params[:id]
  status 200
end

post '/users/new' do
  db.execute(
    "INSERT INTO users (username, name, avatar_url) VALUES (?, ?, ?);",
    [params[:username], params[:name], params[:avatar_url]])
  status 200
end

# *** AUTH ***
post '/authenticate' do
  unless Rpam.auth(params[:username], params[:password])
    status 401
    return
  end

  username =  params[:username]
  new_token = UUID.generate
  puts new_token
  db.execute(
    "UPDATE users SET token = ?, expires = datetime('now', '+1 day') WHERE username = ?;",
    [new_token, username]
  )
  {token: new_token}.to_json
end

post '/validate' do
  username = db.execute(
    "SELECT username FROM users WHERE token = ? AND datetime(expires) > datetime('now') AND is_deleted <> 'true';",
    params[:token]
  )
  if username.length == 0
    status 400
    return
  end
  
  {username: username[0]['username']}.to_json
end

post '/logoff' do
  username = db.execute(
    "UPDATE users SET token = NULL, expires = NULL WHERE token = ? AND datetime(expires) > datetime('now') AND is_deleted <> 'true';",
    params[:token]
  )
  
  status 200
end
