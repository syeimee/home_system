class DashboardController < ApplicationController
  before_action :require_login

  def index
    @artwork = MetArtService.new.current_artwork
    service = SwitchbotService.new
    @devices = service.devices.map do |device|
      status = service.device_status(device['deviceId'])
      {
        id: device['deviceId'],
        name: device['deviceName'],
        type: device['deviceType'],
        power: status&.dig('power') || 'unknown'
      }
    rescue StandardError
      {
        id: device['deviceId'],
        name: device['deviceName'],
        type: device['deviceType'],
        power: 'error'
      }
    end
  end

  def device_on
    SwitchbotService.new.command(params[:id], 'turnOn')
    redirect_to dashboard_path, notice: 'デバイスをONにしました'
  end

  def device_off
    SwitchbotService.new.command(params[:id], 'turnOff')
    redirect_to dashboard_path, notice: 'デバイスをOFFにしました'
  end
end
