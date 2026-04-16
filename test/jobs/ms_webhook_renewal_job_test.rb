require 'test_helper'

class MsWebhookRenewalJobTest < ActiveSupport::TestCase
  test 'perform calls renew_subscription' do
    MicrosoftGraphService.any_instance.expects(:renew_subscription).once
    MsWebhookRenewalJob.perform_now
  end
end
