module Webhooks
  class GoogleController < ApplicationController
    skip_forgery_protection

    def create
      unless valid_webhook_token?
        head :unauthorized
        return
      end

      GoogleCalendarLineNotifyJob.perform_later
      head :ok
    end

    private

    def valid_webhook_token?
      ActiveSupport::SecurityUtils.secure_compare(
        request.headers['X-Goog-Channel-Token'].to_s,
        ENV.fetch('GOOGLE_WEBHOOK_SECRET')
      )
    end
  end
end
