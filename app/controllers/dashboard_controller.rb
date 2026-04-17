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
    service = SwitchbotService.new
    service.command(params[:id], 'turnOn')
    sleep 3
    status = service.device_status(params[:id])
    render json: { power: status&.dig('power') || 'unknown' }
  end

  def device_off
    service = SwitchbotService.new
    service.command(params[:id], 'turnOff')
    sleep 3
    status = service.device_status(params[:id])
    render json: { power: status&.dig('power') || 'unknown' }
  end
end
