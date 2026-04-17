require 'test_helper'

class OutlookPollingJobTest < ActiveSupport::TestCase
  setup do
    @mock_redis = mock('redis')
    @mock_redis.stubs(:get)
    @mock_redis.stubs(:set)
    Redis.stubs(:new).returns(@mock_redis)
  end

  test 'perform syncs interview events and marks as synced' do
    events = [{
      id: 'evt-001',
      subject: '面接 - 候補者A',
      start_time: 2.hours.from_now,
      end_time: 3.hours.from_now
    }]

    google_event = {
      id: 'g-evt1',
      subject: '【面接】面接 - 候補者A',
      start_time: 2.hours.from_now,
      end_time: 3.hours.from_now
    }

    mock_ms = mock('ms_service')
    mock_ms.stubs(:recent_events).returns(events)
    MicrosoftGraphService.stubs(:new).returns(mock_ms)

    mock_google = mock('google_service')
    mock_google.stubs(:create_event).returns(google_event)
    GoogleCalendarService.stubs(:new).returns(mock_google)

    @mock_redis.stubs(:exists?).with('outlook_synced:evt-001').returns(false)
    @mock_redis.expects(:set).with('outlook_synced:evt-001', '1', ex: 30.days.to_i).once

    OutlookPollingJob.perform_now
  end

  test 'perform skips already synced events' do
    events = [{
      id: 'evt-002',
      subject: '面接 - 候補者B',
      start_time: 2.hours.from_now,
      end_time: 3.hours.from_now
    }]

    mock_ms = mock('ms_service')
    mock_ms.stubs(:recent_events).returns(events)
    MicrosoftGraphService.stubs(:new).returns(mock_ms)

    @mock_redis.stubs(:exists?).with('outlook_synced:evt-002').returns(true)

    mock_google = mock('google_service')
    mock_google.expects(:create_event).never
    GoogleCalendarService.stubs(:new).returns(mock_google)

    OutlookPollingJob.perform_now
  end

  test 'perform skips non-interview events' do
    events = [{ id: 'evt-003', subject: 'ランチ', start_time: Time.zone.now, end_time: 1.hour.from_now }]

    mock_ms = mock('ms_service')
    mock_ms.stubs(:recent_events).returns(events)
    MicrosoftGraphService.stubs(:new).returns(mock_ms)

    mock_google = mock('google_service')
    mock_google.expects(:create_event).never
    GoogleCalendarService.stubs(:new).returns(mock_google)

    OutlookPollingJob.perform_now
  end
end
