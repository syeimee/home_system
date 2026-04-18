module Webhooks
  class SwitchbotController < ApplicationController
    skip_forgery_protection

    def create
      event = request.body.read

      unless valid_webhook?(event)
        head :unauthorized
        return
      end

      data = JSON.parse(event)
      context = data['context']
      if context
        device_id = context['deviceMac']&.delete(':')
        power = context['powerState']&.downcase

        if device_id && power
          ActionCable.server.broadcast(
            'device_status',
            { deviceId: device_id, power: }
          )
        end
      end

      head :ok
    end

    private

    def valid_webhook?(body)
      secret = ENV.fetch('SWITCHBOT_WEBHOOK_SECRET', '')
      return true if secret.blank?

      token = request.headers['X-Switchbot-Signature']
      return false unless token

      expected = Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', secret, body))
      ActiveSupport::SecurityUtils.secure_compare(expected, token)
    end
  end
end
