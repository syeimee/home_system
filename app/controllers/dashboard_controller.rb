class DashboardController < ApplicationController
  before_action :require_login

  def index
    @artwork = MetArtService.new.current_artwork
    @events = fetch_events
    @alexa_cookie_expired = AlexaService.cookie_expired?
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
    render json: { status: 'ok' }
  end

  def device_off
    SwitchbotService.new.command(params[:id], 'turnOff')
    render json: { status: 'ok' }
  end

  def artwork
    artwork = MetArtService.new.current_artwork
    render json: artwork || {}
  end

  private

  def fetch_events
    service = GoogleCalendarService.new
    tomorrow_end = (Time.current.in_time_zone + 1.day).end_of_day
    response = service.instance_variable_get(:@service).list_events(
      'primary',
      max_results: 20,
      single_events: true,
      order_by: 'startTime',
      time_min: Time.current.iso8601,
      time_max: tomorrow_end.iso8601
    )
    response.items.map do |e|
      start_time = e.start.date_time || e.start.date
      {
        subject: e.summary,
        start_time: start_time.respond_to?(:in_time_zone) ? start_time.in_time_zone : start_time.to_time.in_time_zone,
        all_day: e.start.date_time.nil?
      }
    end
  rescue StandardError
    []
  end
end
