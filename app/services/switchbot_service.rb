require 'openssl'
require 'securerandom'

class SwitchbotService
  BASE_URL = 'https://api.switch-bot.com/v1.1'.freeze

  def devices
    response = HTTParty.get("#{BASE_URL}/devices", headers: auth_headers)
    response.parsed_response.dig('body', 'deviceList') || []
  end

  def device_status(device_id)
    response = HTTParty.get("#{BASE_URL}/devices/#{device_id}/status", headers: auth_headers)
    response.parsed_response['body']
  end

  def command(device_id, command_type)
    HTTParty.post(
      "#{BASE_URL}/devices/#{device_id}/commands",
      headers: auth_headers.merge('Content-Type' => 'application/json'),
      body: { command: command_type, parameter: 'default', commandType: 'command' }.to_json
    )
  end

  def setup_webhook(url)
    HTTParty.post(
      "#{BASE_URL}/webhook/setupWebhook",
      headers: auth_headers.merge('Content-Type' => 'application/json'),
      body: { action: 'setupWebhook', url:, deviceList: 'ALL' }.to_json
    )
  end

  def query_webhook
    HTTParty.post(
      "#{BASE_URL}/webhook/queryWebhook",
      headers: auth_headers.merge('Content-Type' => 'application/json'),
      body: { action: 'queryUrl' }.to_json
    )
  end

  def delete_webhook(url)
    HTTParty.post(
      "#{BASE_URL}/webhook/deleteWebhook",
      headers: auth_headers.merge('Content-Type' => 'application/json'),
      body: { action: 'deleteWebhook', url: }.to_json
    )
  end

  private

  def auth_headers
    token = ENV.fetch('SWITCHBOT_TOKEN')
    secret = ENV.fetch('SWITCHBOT_SECRET')
    nonce = SecureRandom.uuid
    timestamp = (Time.now.to_f * 1000).to_i.to_s

    sign_data = "#{token}#{timestamp}#{nonce}"
    signature = Base64.strict_encode64(
      OpenSSL::HMAC.digest('SHA256', secret, sign_data)
    )

    {
      'Authorization' => token,
      'sign' => signature,
      'nonce' => nonce,
      't' => timestamp
    }
  end
end
