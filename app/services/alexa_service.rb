class AlexaService
  BASE_URL = 'https://alexa.amazon.co.jp'.freeze

  COOKIE_EXPIRED_KEY = 'alexa:cookie_expired'.freeze

  def announce(message:)
    cookie = load_cookie
    csrf = fetch_csrf(cookie)
    cookie_with_csrf = "#{cookie}; csrf=#{csrf}"
    devices = target_devices(cookie_with_csrf)

    sequence = build_announcement_sequence(message, devices)

    response = HTTParty.post(
      "#{BASE_URL}/api/behaviors/preview",
      headers: {
        'Content-Type' => 'application/json; charset=UTF-8',
        'csrf' => csrf,
        'Cookie' => cookie_with_csrf
      },
      body: { behaviorId: 'PREVIEW', sequenceJson: sequence.to_json }.to_json
    )

    if response.code == 401
      redis.set(COOKIE_EXPIRED_KEY, '1')
      Rails.logger.error '[AlexaService] Cookie expired (401)'
    else
      redis.del(COOKIE_EXPIRED_KEY)
    end

    response
  end

  def self.cookie_expired?
    Redis.new(url: ENV.fetch('REDIS_URL')).exists?(COOKIE_EXPIRED_KEY)
  end

  private

  def redis
    @redis ||= Redis.new(url: ENV.fetch('REDIS_URL'))
  end

  def load_cookie
    redis.get('alexa:cookie') ||
      raise('Alexa cookie not found. Run alexa-cookie-cli to set up.')
  end

  def fetch_csrf(cookie)
    response = HTTParty.get(
      "#{BASE_URL}/api/language",
      headers: { 'Cookie' => cookie },
      follow_redirects: false
    )
    set_cookie = response.headers['set-cookie']
    set_cookie&.match(/csrf=([^;]+)/)&.captures&.first # rubocop:disable Style/SafeNavigationChainLength
  end

  def target_devices(cookie)
    response = HTTParty.get(
      "#{BASE_URL}/api/devices-v2/device?cached=true",
      headers: { 'Cookie' => cookie }
    )
    all_devices = response.parsed_response['devices'] || []
    all_devices.select { |d| %w[ECHO KNIGHT].any? { |f| d['deviceFamily']&.include?(f) } }
  end

  def build_announcement_sequence(message, devices)
    {
      '@type': 'com.amazon.alexa.behaviors.model.Sequence',
      startNode: build_announcement_node(message, devices)
    }
  end

  def announcement_content(message)
    { locale: 'ja-JP', display: { title: 'Home System', body: message }, speak: { type: 'text', value: message } }
  end

  def announcement_target(devices)
    {
      customerId: devices.first&.dig('deviceOwnerCustomerId'),
      devices: devices.map { |d| { deviceSerialNumber: d['serialNumber'], deviceTypeId: d['deviceType'] } }
    }
  end

  def build_announcement_node(message, devices)
    {
      '@type': 'com.amazon.alexa.behaviors.model.OpaquePayloadOperationNode',
      type: 'AlexaAnnouncement',
      operationPayload: {
        expireAfter: 'PT5S',
        content: [announcement_content(message)],
        target: announcement_target(devices)
      }
    }
  end
end
