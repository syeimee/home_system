class DashboardController < ApplicationController
  before_action :require_login

  def index
    @devices = Settings[:switchbot][:devices]
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
