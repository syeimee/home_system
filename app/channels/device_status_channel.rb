class DeviceStatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'device_status'
  end
end
