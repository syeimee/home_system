require 'test_helper'

class SwitchbotServiceTest < ActiveSupport::TestCase
  setup do
    @service = SwitchbotService.new
  end

  test 'devices returns device list from API' do
    stub_request(:get, 'https://api.switch-bot.com/v1.1/devices')
      .to_return(
        status: 200,
        body: { statusCode: 100, body: { deviceList: [{ deviceId: 'abc', deviceName: 'Light' }] } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.devices

    assert_equal 1, result.size
    assert_equal 'abc', result.first['deviceId']
  end

  test 'device_status returns status for a device' do
    stub_request(:get, 'https://api.switch-bot.com/v1.1/devices/abc/status')
      .to_return(
        status: 200,
        body: { statusCode: 100, body: { power: 'on' } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.device_status('abc')

    assert_equal 'on', result['power']
  end

  test 'command sends command to device' do
    stub_request(:post, 'https://api.switch-bot.com/v1.1/devices/abc/commands')
      .with(body: { command: 'turnOn', parameter: 'default', commandType: 'command' }.to_json)
      .to_return(status: 200, body: { statusCode: 100 }.to_json)

    response = @service.command('abc', 'turnOn')

    assert_equal 200, response.code
  end
end
