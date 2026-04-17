class DashboardController < ApplicationController
  before_action :require_login

  def index
    @devices = Settings[:switchbot][:devices].map do |device|
      status = SwitchbotService.new.device_status(device[:id])
      device.merge(power: status&.dig('power') || 'unknown')
    rescue StandardError
      device.merge(power: 'error')
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
