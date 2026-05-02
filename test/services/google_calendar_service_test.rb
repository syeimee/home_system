require 'test_helper'

class GoogleCalendarServiceTest < ActiveSupport::TestCase
  setup do
    TokenStore.any_instance.stubs(:google_refresh_token).returns('test-refresh-token')
  end

  test 'recent_events returns formatted events' do
    mock_event = Struct.new(:id, :summary, :start, :end, :created, :updated, keyword_init: true)
    mock_dt = Struct.new(:date_time, :date, keyword_init: true)
    now = Time.zone.now
    event = mock_event.new(
      id: 'evt1',
      summary: 'テスト予定',
      start: mock_dt.new(date_time: Time.zone.parse('2026-05-10 14:00').to_datetime),
      end: mock_dt.new(date_time: Time.zone.parse('2026-05-10 15:00').to_datetime),
      created: now,
      updated: now
    )

    mock_response = Struct.new(:items, keyword_init: true).new(items: [event])

    Google::Apis::CalendarV3::CalendarService.any_instance.stubs(:list_events).returns(mock_response)
    Google::Auth::UserRefreshCredentials.stubs(:new).returns(stub)

    service = GoogleCalendarService.new
    events = service.recent_events

    assert_equal 1, events.size
    assert_equal 'テスト予定', events.first[:subject]
  end

  test 'create_event calls Google API and returns formatted event' do
    mock_dt = Struct.new(:date_time, :date, keyword_init: true)
    now = Time.zone.now
    mock_event = Struct.new(:id, :summary, :start, :end, :created, :updated, keyword_init: true).new(
      id: 'new-evt',
      summary: '【面接】候補者B',
      start: mock_dt.new(date_time: Time.zone.parse('2026-05-10 14:00').to_datetime),
      end: mock_dt.new(date_time: Time.zone.parse('2026-05-10 15:00').to_datetime),
      created: now,
      updated: now
    )

    Google::Apis::CalendarV3::CalendarService.any_instance.stubs(:insert_event).returns(mock_event)
    Google::Auth::UserRefreshCredentials.stubs(:new).returns(stub)

    service = GoogleCalendarService.new
    result = service.create_event(
      title: '【面接】候補者B',
      start_time: Time.zone.parse('2026-05-10 14:00'),
      end_time: Time.zone.parse('2026-05-10 15:00')
    )

    assert_equal '【面接】候補者B', result[:subject]
  end
end
