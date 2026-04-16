class MsWebhookRenewalJob < ApplicationJob
  queue_as :default

  def perform
    MicrosoftGraphService.new.renew_subscription
  end
end
