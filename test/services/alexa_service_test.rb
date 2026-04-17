require 'test_helper'

class AlexaServiceTest < ActiveSupport::TestCase
  test 'announce sends POST to alexa container' do
    stub_request(:post, 'http://alexa:3100/announce')
      .with(
        body: { message: 'テスト通知' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      .to_return(status: 200, body: '{"status":"ok"}')

    service = AlexaService.new
    response = service.announce(message: 'テスト通知')

    assert_equal 200, response.code
  end
end
