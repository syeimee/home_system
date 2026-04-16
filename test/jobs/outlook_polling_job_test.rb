require 'test_helper'

class OutlookPollingJobTest < ActiveSupport::TestCase
  setup do
    @redis = mock('redis')
    Redis.stubs(:new).returns(@redis)
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

    MicrosoftGraphService.any_instance.stubs(:recent_events).returns(events)
    @redis.stubs(:exists?).with('outlook_synced:evt-001').returns(false)
    @redis.expects(:set).with('outlook_synced:evt-001', '1', ex: 30.days.to_i).once
    GoogleCalendarService.any_instance.stubs(:create_event).returns(google_event)

    assert_enqueued_with(job: AlexaAnnounceJob) do
      OutlookPollingJob.perform_now
    end
  end

  test 'perform skips already synced events' do
    events = [{
      id: 'evt-002',
      subject: '面接 - 候補者B',
      start_time: 2.hours.from_now,
      end_time: 3.hours.from_now
    }]

    MicrosoftGraphService.any_instance.stubs(:recent_events).returns(events)
    @redis.stubs(:exists?).with('outlook_synced:evt-002').returns(true)
    GoogleCalendarService.any_instance.expects(:create_event).never

    OutlookPollingJob.perform_now
  end

  test 'perform skips non-interview events' do
    events = [{ id: 'evt-003', subject: 'ランチ', start_time: Time.zone.now, end_time: 1.hour.from_now }]

    MicrosoftGraphService.any_instance.stubs(:recent_events).returns(events)
    GoogleCalendarService.any_instance.expects(:create_event).never

    OutlookPollingJob.perform_now
  end
end
