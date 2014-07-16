# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_luleka_session',
  :secret      => '107f0862048a72d2171a2e479e863ddbd308964c9c90205be2ea500121d574888d7b30551867e88c02a761abf0f0c8869db2c77fe552e086b9fc22a96d878def'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
