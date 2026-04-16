require 'test_helper'

module Webhooks
  class OutlookControllerTest < ActionDispatch::IntegrationTest
    test 'POST /webhooks/outlook returns validation token when present' do
      post webhooks_outlook_path, params: { validationToken: 'abc123' }

      assert_response :ok
      assert_equal 'abc123', response.body
    end

    test 'POST /webhooks/outlook returns unauthorized without valid clientState' do
      post webhooks_outlook_path,
           params: { value: [{ clientState: 'wrong' }] },
           as: :json

      assert_response :unauthorized
    end

    test 'POST /webhooks/outlook enqueues job with valid clientState' do
      assert_enqueued_with(job: OutlookSyncJob) do
        post webhooks_outlook_path,
             params: { value: [{ clientState: ENV.fetch('MS_WEBHOOK_SECRET') }] },
             as: :json
      end
      assert_response :ok
    end
  end
end
