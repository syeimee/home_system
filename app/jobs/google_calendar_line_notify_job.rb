class GoogleCalendarLineNotifyJob < ApplicationJob
  queue_as :webhooks

  NOTIFIED_KEY = 'line_notified_events'.freeze

  def perform
    events = GoogleCalendarService.new.recent_events
    return if events.empty?

    events.each do |event|
      next if already_notified?(event[:id])

      LineService.new.notify_event(event)
      mark_notified(event[:id])
      schedule_interview_alerts(event) if interview_event?(event)
    end
  end

  private

  def already_notified?(event_id)
    redis.sismember(NOTIFIED_KEY, event_id)
  end

  def mark_notified(event_id)
    redis.sadd(NOTIFIED_KEY, event_id)
    redis.expire(NOTIFIED_KEY, 24.hours.to_i)
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
  end

  def interview_event?(event)
    subject = event[:subject].to_s
    Settings[:interview][:keywords].any? { |kw| subject.downcase.include?(kw.downcase) }
  end

  def schedule_interview_alerts(event)
    start_time = event[:start_time]
    return if start_time.nil? || start_time.respond_to?(:past?) && start_time.past?

    Settings[:interview][:notify_before_minutes].each do |minutes|
      alert_time = start_time - minutes.minutes
      next if alert_time.past?

      AlexaAnnounceJob.set(wait_until: alert_time).perform_later(minutes)
    end
  end
end
