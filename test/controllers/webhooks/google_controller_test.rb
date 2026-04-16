require 'test_helper'

module Webhooks
  class GoogleControllerTest < ActionDispatch::IntegrationTest
    test 'POST /webhooks/google returns unauthorized without valid token' do
      post webhooks_google_path

      assert_response :unauthorized
    end

    test 'POST /webhooks/google enqueues job with valid token' do
      assert_enqueued_with(job: GoogleCalendarLineNotifyJob) do
        post webhooks_google_path, headers: { 'X-Goog-Channel-Token' => ENV.fetch('GOOGLE_WEBHOOK_SECRET') }
      end
      assert_response :ok
    end
  end
end
