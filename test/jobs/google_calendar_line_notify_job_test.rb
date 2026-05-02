require 'test_helper'

class GoogleCalendarLineNotifyJobTest < ActiveSupport::TestCase
  setup do
    redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
    redis.del('line_notified_events')
  end

  test 'perform fetches events and sends LINE notifications' do
    now = Time.zone.now
    events = [{ id: 'event_1', subject: '予定A', start_time: now, updated: now }]

    mock_calendar = mock('google_calendar_service')
    mock_calendar.stubs(:recent_events).returns(events)
    GoogleCalendarService.stubs(:new).returns(mock_calendar)

    mock_line = mock('line_service')
    mock_line.expects(:notify_event).with(events.first).once
    LineService.stubs(:new).returns(mock_line)

    GoogleCalendarLineNotifyJob.perform_now
  end

  test 'perform notifies again when event is updated' do
    now = Time.zone.now
    original_event = { id: 'event_1', subject: '予定A', start_time: now, updated: now }
    updated_event = { id: 'event_1', subject: '予定A（変更）', start_time: now, updated: now + 5.minutes }

    mock_calendar = mock('google_calendar_service')
    mock_line = mock('line_service')

    # First notification
    mock_calendar.stubs(:recent_events).returns([original_event])
    GoogleCalendarService.stubs(:new).returns(mock_calendar)
    mock_line.expects(:notify_event).with(original_event).once
    LineService.stubs(:new).returns(mock_line)
    GoogleCalendarLineNotifyJob.perform_now

    # Second notification after update
    mock_calendar.stubs(:recent_events).returns([updated_event])
    mock_line.expects(:notify_event).with(updated_event).once
    GoogleCalendarLineNotifyJob.perform_now
  end

  test 'perform schedules Alexa alerts for interview events' do
    start_time = 30.minutes.from_now
    events = [{ id: 'event_interview', subject: 'Technical Interview', start_time: start_time, updated: Time.zone.now }]

    mock_calendar = mock('google_calendar_service')
    mock_calendar.stubs(:recent_events).returns(events)
    GoogleCalendarService.stubs(:new).returns(mock_calendar)

    mock_line = mock('line_service')
    mock_line.stubs(:notify_event)
    LineService.stubs(:new).returns(mock_line)

    assert_enqueued_with(job: AlexaAnnounceJob, args: [15]) do
      assert_enqueued_with(job: AlexaAnnounceJob, args: [5]) do
        GoogleCalendarLineNotifyJob.perform_now
      end
    end
  end

  test 'perform does not schedule Alexa alerts for non-interview events' do
    events = [{ id: 'event_meeting', subject: '定例ミーティング', start_time: 30.minutes.from_now, updated: Time.zone.now }]

    mock_calendar = mock('google_calendar_service')
    mock_calendar.stubs(:recent_events).returns(events)
    GoogleCalendarService.stubs(:new).returns(mock_calendar)

    mock_line = mock('line_service')
    mock_line.stubs(:notify_event)
    LineService.stubs(:new).returns(mock_line)

    assert_no_enqueued_jobs(only: AlexaAnnounceJob) do
      GoogleCalendarLineNotifyJob.perform_now
    end
  end

  test 'perform skips past alert times' do
    start_time = 3.minutes.from_now
    events = [{ id: 'event_soon', subject: '面接', start_time: start_time, updated: Time.zone.now }]

    mock_calendar = mock('google_calendar_service')
    mock_calendar.stubs(:recent_events).returns(events)
    GoogleCalendarService.stubs(:new).returns(mock_calendar)

    mock_line = mock('line_service')
    mock_line.stubs(:notify_event)
    LineService.stubs(:new).returns(mock_line)

    # 15min before is already past, only 5min should be scheduled (but it's also past if start is 3min away)
    # Actually 3 minutes from now: 15min before = past, 5min before = past
    assert_no_enqueued_jobs(only: AlexaAnnounceJob) do
      GoogleCalendarLineNotifyJob.perform_now
    end
  end

  test 'perform does nothing when no events' do
    mock_calendar = mock('google_calendar_service')
    mock_calendar.stubs(:recent_events).returns([])
    GoogleCalendarService.stubs(:new).returns(mock_calendar)

    LineService.any_instance.expects(:notify_event).never

    GoogleCalendarLineNotifyJob.perform_now
  end
end
