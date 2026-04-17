module Webhooks
  class SwitchbotController < ApplicationController
    skip_forgery_protection

    def create
      event = request.body.read
      data = JSON.parse(event)

      context = data['context']
      if context
        device_id = context['deviceMac']&.delete(':')
        power = context['powerState']

        if device_id && power
          ActionCable.server.broadcast(
            'device_status',
            { deviceId: device_id, power: }
          )
        end
      end

      head :ok
    end
  end
end
