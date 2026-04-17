require 'test_helper'

class OutlookSyncJobTest < ActiveSupport::TestCase
  setup do
    TokenStore.any_instance.stubs(:ms_refresh_token).returns('test-token')
    TokenStore.any_instance.stubs(:save_ms_refresh_token)
    TokenStore.any_instance.stubs(:google_refresh_token).returns('test-token')
  end

  test 'perform syncs interview events to Google Calendar and schedules Alexa jobs' do
    events = [{
      subject: '面接 - 候補者A',
      start_time: 2.hours.from_now,
      end_time: 3.hours.from_now
    }]

    google_event = {
      id: 'evt1',
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

    assert_enqueued_with(job: AlexaAnnounceJob) do
      OutlookSyncJob.perform_now
    end
  end

  test 'perform skips non-interview events' do
    events = [{ subject: 'ランチ', start_time: Time.zone.now, end_time: 1.hour.from_now }]

    mock_ms = mock('ms_service')
    mock_ms.stubs(:recent_events).returns(events)
    MicrosoftGraphService.stubs(:new).returns(mock_ms)

    mock_google = mock('google_service')
    mock_google.expects(:create_event).never
    GoogleCalendarService.stubs(:new).returns(mock_google)

    OutlookSyncJob.perform_now
  end
end
