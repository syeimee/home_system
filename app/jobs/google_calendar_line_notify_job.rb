class GoogleCalendarLineNotifyJob < ApplicationJob
  queue_as :webhooks

  def perform
    events = GoogleCalendarService.new.recent_events
    return if events.empty?

    events.each do |event|
      LineService.new.notify_event(event)
    end
  end
end
