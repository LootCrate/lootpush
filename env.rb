# required environment variables
# these values should be retrieved via chamber, eg chamber exec loot-crate-ios -- ..
GOOGLE_PRIVATE_KEY = ENV.fetch("GOOGLE_PRIVATE_KEY")
GOOGLE_CLIENT_EMAIL = ENV.fetch("GOOGLE_CLIENT_EMAIL")
FIREBASE_PROJECT_ID = ENV.fetch("FIREBASE_PROJECT_ID")
FIREBASE_CLOUD_MESSAGING_SERVER_KEY = ENV.fetch("FIREBASE_CLOUD_MESSAGING_SERVER_KEY")
LOOTCRATE_DATABASE_URL = ENV.fetch("LOOTCRATE_DATABASE_URL")