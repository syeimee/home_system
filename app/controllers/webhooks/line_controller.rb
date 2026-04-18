module Webhooks
  class LineController < ApplicationController
    skip_forgery_protection

    def create
      body = request.body.read
      return head :ok if body.blank?

      parsed = begin
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end
      events = parsed['events'] || []

      events.each do |event|
        source = event['source'] || {}
        Rails.logger.info "[LINE Webhook] type=#{source['type']} " \
                          "groupId=#{source['groupId']} userId=#{source['userId']}"
      end

      head :ok
    end
  end
end
