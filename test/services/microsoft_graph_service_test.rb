require 'test_helper'

class MicrosoftGraphServiceTest < ActiveSupport::TestCase
  setup do
    TokenStore.any_instance.stubs(:ms_refresh_token).returns('test-ms-refresh-token')
    TokenStore.any_instance.stubs(:save_ms_refresh_token)
    stub_token_request
    @service = MicrosoftGraphService.new
  end

  test 'recent_events returns parsed events' do
    stub_request(:get, %r{graph\.microsoft\.com/v1\.0/me/calendarView})
      .to_return(
        status: 200,
        body: {
          value: [{
            subject: '面接 - 候補者A',
            start: { dateTime: '2026-05-10T14:00:00' },
            end: { dateTime: '2026-05-10T15:00:00' }
          }]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    events = @service.recent_events

    assert_equal 1, events.size
    assert_equal '面接 - 候補者A', events.first[:subject]
  end

  private

  def stub_token_request
    stub_request(:post, %r{login\.microsoftonline\.com/.*/oauth2/v2\.0/token})
      .to_return(
        status: 200,
        body: { access_token: 'test-access-token', expires_in: 3600 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
