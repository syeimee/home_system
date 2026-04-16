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
      request.headers['X-Goog-Channel-Token'] == ENV.fetch('GOOGLE_WEBHOOK_SECRET')
    end
  end
end
