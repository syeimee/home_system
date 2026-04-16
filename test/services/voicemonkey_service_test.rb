require 'test_helper'

class VoicemonkeyServiceTest < ActiveSupport::TestCase
  test 'announce sends request to VoiceMonkey API' do
    stub_request(:post, 'https://api.voicemonkey.io/trigger')
      .with(query: hash_including(
        'token' => 'test-voicemonkey-token',
        'device' => 'living-room-echo',
        'text' => 'テスト通知'
      ))
      .to_return(status: 200, body: '{}')

    service = VoicemonkeyService.new
    response = service.announce(device: 'living-room-echo', message: 'テスト通知')

    assert_equal 200, response.code
  end
end
