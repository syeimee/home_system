module Webhooks
  class LineController < ApplicationController
    skip_forgery_protection

    def create
      body = request.body.read
      return head :ok if body.blank?

      unless valid_signature?(body)
        head :unauthorized
        return
      end

      parsed = begin
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end
      events = parsed['events'] || []

      events.each do |event|
        source = event['source'] || {}
        Rails.logger.info "[LINE Webhook] type=#{source['type']} " \
                          "groupId=#{source['groupId']}"
      end

      head :ok
    end

    private

    def valid_signature?(body)
      signature = request.headers['X-Line-Signature']
      return false unless signature

      hash = OpenSSL::HMAC.digest('SHA256', ENV.fetch('LINE_CHANNEL_SECRET'), body)
      ActiveSupport::SecurityUtils.secure_compare(Base64.strict_encode64(hash), signature)
    end
  end
end
