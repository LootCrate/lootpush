### HOW TO RUN THIS SCRIPT
#
#  $ aws-vault exec lootcrate-prod-admin -- chamber exec loot-crate-ios -- bundle exec ruby push.rb test.yaml
#

require 'rubygems'
require 'bundler/setup'

require 'http'
require 'yaml'
require 'semantic_logger'
require 'firebase_cloud_messenger'
require 'sequel'
require 'pg'
require 'pry'

require './env.rb'

logger = SemanticLogger['LootPush']
SemanticLogger.add_appender(io: $stdout, formatter: :color, level: :debug)
DB = Sequel.connect(LOOTCRATE_DATABASE_URL) # , logger: logger)
FirebaseCloudMessenger.project_id = FIREBASE_PROJECT_ID

###################################################
## 1. Parse config yaml                          ##
###################################################
config_file = ARGV[0]
logger.info("Loading config from #{config_file}")
message_config = YAML.load_file(config_file)['message']

message_topic = "#{message_config['topic']}"
message_title = message_config['title']
message_body = message_config['body']
message_recipients = message_config['recipients']

logger.info("Push Notification Topic: #{message_topic}")
logger.info("Push Notification Title: #{message_title}")
logger.info("Push Notification Message: #{message_body}")
logger.info("Email address count: #{message_recipients.count}")

###########################################################
##  2. Lookup firebase registration keys for             ##
##  each email address and subscribe them to the topic   ##
###########################################################
tokens = []
message_recipients.each_slice(1000) do |emails|
  devices = DB[:devices].join(:users, id: :user_id).where(email: emails, status: 0).select(:firebase_registration_token)
  tokens.push(*devices.map(:firebase_registration_token).uniq)
end
logger.info("Found matching #{tokens.count} registered devices with notifications enabled")

## Batch add the devices to the topic
logger.info("Subscribing devices to topic #{message_topic} in batches of 1,000")
google_api_headers = {
  "Content-Type": "application/json",
  "Authorization": "key=#{FIREBASE_CLOUD_MESSAGING_SERVER_KEY}"
}
tokens.each_slice(1000) do |tokens_slice| 
  body = {
    to: "/topics/#{message_topic}",
    registration_tokens: tokens_slice
  }
  HTTP.use(logging: {logger: logger}).headers(google_api_headers).post('https://iid.googleapis.com/iid/v1:batchAdd', json: body)
end

###################################################
## 3. Create FCM message and send the push       ##
## notifcation to the topic                      ##
###################################################
notification = FirebaseCloudMessenger::Notification.new(title: message_title, body: message_body)
message = FirebaseCloudMessenger::Message.new(topic: message_topic, notification: notification)
if message.valid?(against_api: true)
  begin
    FirebaseCloudMessenger.send(message: message)
  rescue FirebaseCloudMessenger::Error => e
    logger.error(e)
  end
else
  logger.warn("Invalid message. #{message.errors}")
end
