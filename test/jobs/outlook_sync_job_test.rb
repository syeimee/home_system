require 'test_helper'

class OutlookSyncJobTest < ActiveSupport::TestCase
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

    MicrosoftGraphService.any_instance.stubs(:recent_events).returns(events)
    GoogleCalendarService.any_instance.stubs(:create_event).returns(google_event)

    assert_enqueued_with(job: AlexaAnnounceJob) do
      OutlookSyncJob.perform_now
    end
  end

  test 'perform skips non-interview events' do
    events = [{ subject: 'ランチ', start_time: Time.zone.now, end_time: 1.hour.from_now }]

    MicrosoftGraphService.any_instance.stubs(:recent_events).returns(events)
    GoogleCalendarService.any_instance.expects(:create_event).never

    OutlookSyncJob.perform_now
  end
end
