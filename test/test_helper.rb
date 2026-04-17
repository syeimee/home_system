ENV['RAILS_ENV'] ||= 'test'

# Stub environment variables for tests
ENV['GOOGLE_CLIENT_ID'] ||= 'test-google-client-id'
ENV['GOOGLE_CLIENT_SECRET'] ||= 'test-google-client-secret'
ENV['GOOGLE_WEBHOOK_SECRET'] ||= 'test-google-webhook-secret'
ENV['LINE_CHANNEL_TOKEN'] ||= 'test-line-channel-token'
ENV['SWITCHBOT_TOKEN'] ||= 'test-switchbot-token'
ENV['SWITCHBOT_SECRET'] ||= 'test-switchbot-secret'
ENV['REDIS_URL'] ||= 'redis://localhost:6379'

require_relative '../config/environment'
require 'rails/test_help'
require 'webmock/minitest'
require 'mocha/minitest'

WebMock.disable_net_connect!

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper
  end
end
