class GoogleCalendarLineNotifyJob < ApplicationJob
  queue_as :webhooks

  def perform
    events = GoogleCalendarService.new.recent_events
    return if events.empty?

    events.each do |event|
      LineService.new.notify_event(event)
      schedule_interview_alerts(event) if interview_event?(event)
    end
  end

  private

  def interview_event?(event)
    subject = event[:subject].to_s
    Settings[:interview][:keywords].any? { |kw| subject.downcase.include?(kw.downcase) }
  end

  def schedule_interview_alerts(event)
    start_time = event[:start_time]
    return if start_time.nil? || start_time.past?

    Settings[:interview][:notify_before_minutes].each do |minutes|
      alert_time = start_time - minutes.minutes
      next if alert_time.past?

      AlexaAnnounceJob.set(wait_until: alert_time).perform_later(minutes)
    end
  end
end
