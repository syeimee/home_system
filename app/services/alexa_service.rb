class AlexaService
  BASE_URL = 'http://alexa:3100'.freeze

  def announce(message:)
    HTTParty.post(
      "#{BASE_URL}/announce",
      headers: { 'Content-Type' => 'application/json' },
      body: { message: }.to_json
    )
  end
end
