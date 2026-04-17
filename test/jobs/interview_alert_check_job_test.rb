require 'test_helper'

class InterviewAlertCheckJobTest < ActiveSupport::TestCase
  setup do
    @redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
    @redis.del(InterviewAlertCheckJob::SCHEDULED_KEY)
  end

  test 'schedules Alexa alerts for upcoming interview events' do
    events = [{ id: 'evt1', subject: 'Technical Interview', start_time: 30.minutes.from_now }]

    mock_calendar = mock('google_calendar_service')
    mock_calendar.stubs(:upcoming_events).returns(events)
    GoogleCalendarService.stubs(:new).returns(mock_calendar)

    assert_enqueued_with(job: AlexaAnnounceJob, args: [15]) do
      assert_enqueued_with(job: AlexaAnnounceJob, args: [5]) do
        InterviewAlertCheckJob.perform_now
      end
    end
  end

  test 'skips non-interview events' do
    events = [{ id: 'evt2', subject: 'Team Standup', start_time: 30.minutes.from_now }]

    mock_calendar = mock('google_calendar_service')
    mock_calendar.stubs(:upcoming_events).returns(events)
    GoogleCalendarService.stubs(:new).returns(mock_calendar)

    assert_no_enqueued_jobs(only: AlexaAnnounceJob) do
      InterviewAlertCheckJob.perform_now
    end
  end

  test 'does not double-schedule alerts for the same event' do
    events = [{ id: 'evt3', subject: '面接', start_time: 30.minutes.from_now }]

    mock_calendar = mock('google_calendar_service')
    mock_calendar.stubs(:upcoming_events).returns(events)
    GoogleCalendarService.stubs(:new).returns(mock_calendar)

    InterviewAlertCheckJob.perform_now
    clear_enqueued_jobs

    assert_no_enqueued_jobs(only: AlexaAnnounceJob) do
      InterviewAlertCheckJob.perform_now
    end
  end

  test 'skips events with past start time' do
    events = [{ id: 'evt4', subject: 'interview', start_time: 10.minutes.ago }]

    mock_calendar = mock('google_calendar_service')
    mock_calendar.stubs(:upcoming_events).returns(events)
    GoogleCalendarService.stubs(:new).returns(mock_calendar)

    assert_no_enqueued_jobs(only: AlexaAnnounceJob) do
      InterviewAlertCheckJob.perform_now
    end
  end
end
