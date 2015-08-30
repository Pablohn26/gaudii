# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_gaudii_session',
  :secret      => 'fe04b8752386dedfabe08575cdd79ac1374f5e8348dae3912dfe5daab69b44eba3483ff6c48421754200f3a67e6b057ffb87ff75c2aa4d37961fa950d9e2687b'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store
