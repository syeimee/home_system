class VoicemonkeyService
  API_URL = 'https://api.voicemonkey.io/trigger'.freeze

  def announce(device:, message:)
    HTTParty.post(API_URL, query: {
                    token: ENV.fetch('VOICEMONKEY_TOKEN'),
                    device:,
                    text: message
                  })
  end
end
