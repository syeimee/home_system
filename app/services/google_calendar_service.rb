class GoogleCalendarService
  CALENDAR_ID = 'primary'.freeze

  def initialize
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = google_credentials
  end

  def recent_events
    response = @service.list_events(
      CALENDAR_ID,
      max_results: 5,
      single_events: true,
      order_by: 'startTime',
      time_min: Time.current.beginning_of_day.iso8601,
      updated_min: 6.minutes.ago.iso8601
    )
    response.items.map { |e| format_event(e) }
  end

  def upcoming_events
    response = @service.list_events(
      CALENDAR_ID,
      max_results: 10,
      single_events: true,
      order_by: 'startTime',
      time_min: Time.current.iso8601,
      time_max: Time.current.in_time_zone.end_of_day.iso8601
    )
    response.items.map { |e| format_event(e) }
  end

  def create_event(title:, start_time:, end_time:)
    event = Google::Apis::CalendarV3::Event.new(
      summary: title,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_time.iso8601),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: end_time.iso8601)
    )
    result = @service.insert_event(CALENDAR_ID, event)
    format_event(result)
  end

  private

  def google_credentials
    refresh_token = TokenStore.new.google_refresh_token
    raise 'Google refresh token not found. Please log in first.' unless refresh_token

    Google::Auth::UserRefreshCredentials.new(
      client_id: ENV.fetch('GOOGLE_CLIENT_ID'),
      client_secret: ENV.fetch('GOOGLE_CLIENT_SECRET'),
      refresh_token:,
      scope: ['https://www.googleapis.com/auth/calendar']
    )
  end

  def format_event(event)
    all_day = event.start.date_time.nil?
    start_time = event.start.date_time || Date.parse(event.start.date.to_s)
    end_time = event.end&.date_time || (event.end&.date && Date.parse(event.end.date.to_s))
    {
      id: event.id,
      subject: event.summary,
      start_time: all_day ? start_time : start_time.to_time.in_time_zone,
      end_time: all_day ? end_time : end_time&.to_time&.in_time_zone,
      all_day: all_day
    }
  end
end
