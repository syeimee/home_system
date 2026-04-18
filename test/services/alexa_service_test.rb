require 'test_helper'

class AlexaServiceTest < ActiveSupport::TestCase
  setup do
    @redis = mock('redis')
    Redis.stubs(:new).returns(@redis)
    @redis.stubs(:get).with('alexa:cookie').returns('test-cookie')
  end

  test 'announce fetches CSRF, devices, and sends announcement' do
    stub_request(:get, 'https://alexa.amazon.co.jp/api/language')
      .to_return(status: 200, headers: { 'set-cookie' => 'csrf=12345; Path=/' })

    stub_request(:get, %r{alexa\.amazon\.co\.jp/api/devices-v2/device})
      .to_return(
        status: 200,
        body: {
          devices: [{
            'accountName' => 'Echo Show',
            'serialNumber' => 'SERIAL123',
            'deviceType' => 'TYPE123',
            'deviceFamily' => 'ECHO',
            'deviceOwnerCustomerId' => 'CUST123'
          }]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:post, 'https://alexa.amazon.co.jp/api/behaviors/preview')
      .to_return(status: 200)

    service = AlexaService.new
    response = service.announce(message: 'テスト')

    assert_equal 200, response.code
  end
end
