require 'test_helper'

class GoogleCalendarLineNotifyJobTest < ActiveSupport::TestCase
  test 'perform fetches events and sends LINE notifications' do
    events = [{ subject: '予定A', start_time: Time.zone.now }]

    GoogleCalendarService.any_instance.stubs(:recent_events).returns(events)

    mock_line = mock('line_service')
    mock_line.expects(:notify_event).with(events.first).once
    LineService.stubs(:new).returns(mock_line)

    GoogleCalendarLineNotifyJob.perform_now
  end

  test 'perform does nothing when no events' do
    GoogleCalendarService.any_instance.stubs(:recent_events).returns([])
    LineService.any_instance.expects(:notify_event).never

    GoogleCalendarLineNotifyJob.perform_now
  end
end
