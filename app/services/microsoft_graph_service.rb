class MicrosoftGraphService
  BASE_URL = 'https://graph.microsoft.com/v1.0'.freeze

  SUBSCRIPTION_EXPIRY_HOURS = 48

  def recent_events
    response = HTTParty.get(
      "#{BASE_URL}/me/calendarView",
      headers: auth_headers,
      query: {
        startDateTime: 1.minute.ago.iso8601,
        endDateTime: 1.day.from_now.iso8601,
        '$orderby' => 'createdDateTime desc',
        '$top' => 5
      }
    )
    parse_events(response)
  end

  def renew_subscription
    subscription_id = Redis.new(url: ENV.fetch('REDIS_URL')).get('ms_webhook_subscription_id')
    return create_subscription unless subscription_id

    HTTParty.patch(
      "#{BASE_URL}/subscriptions/#{subscription_id}",
      headers: auth_headers,
      body: { expirationDateTime: SUBSCRIPTION_EXPIRY_HOURS.hours.from_now.iso8601 }.to_json
    )
  end

  def create_subscription
    response = HTTParty.post(
      "#{BASE_URL}/subscriptions",
      headers: auth_headers,
      body: {
        changeType: 'created,updated',
        notificationUrl: "#{Settings[:app][:webhook_url]}/webhooks/outlook",
        resource: 'me/events',
        expirationDateTime: SUBSCRIPTION_EXPIRY_HOURS.hours.from_now.iso8601,
        clientState: ENV.fetch('MS_WEBHOOK_SECRET')
      }.to_json
    )
    subscription = response.parsed_response
    Redis.new(url: ENV.fetch('REDIS_URL')).set('ms_webhook_subscription_id', subscription['id'])
    subscription
  end

  private

  def auth_headers
    { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' }
  end

  def access_token
    store = TokenStore.new
    refresh_token = store.ms_refresh_token
    raise 'Microsoft refresh token not found. Please link your Microsoft account.' unless refresh_token

    response = HTTParty.post(
      "https://login.microsoftonline.com/#{ENV.fetch('MS_TENANT_ID')}/oauth2/v2.0/token",
      body: {
        client_id: ENV.fetch('MS_CLIENT_ID'),
        client_secret: ENV.fetch('MS_CLIENT_SECRET'),
        refresh_token:,
        grant_type: 'refresh_token',
        scope: 'https://graph.microsoft.com/.default'
      }
    )

    data = response.parsed_response
    # Microsoft はリフレッシュトークンをローテーションすることがある
    store.save_ms_refresh_token(data['refresh_token']) if data['refresh_token']
    data['access_token']
  end

  def parse_events(response)
    (response.parsed_response['value'] || []).map do |event|
      {
        id: event['id'],
        subject: event['subject'],
        start_time: Time.parse(event.dig('start', 'dateTime')).in_time_zone,
        end_time: Time.parse(event.dig('end', 'dateTime')).in_time_zone
      }
    end
  end
end
