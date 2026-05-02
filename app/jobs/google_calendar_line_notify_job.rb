class GoogleCalendarLineNotifyJob < ApplicationJob
  queue_as :webhooks

  NOTIFIED_KEY = 'line_notified_events'.freeze

  def perform
    events = GoogleCalendarService.new.recent_events
    return if events.empty?

    events.each do |event|
      notification_key = build_notification_key(event)
      next if already_notified?(notification_key)

      LineService.new.notify_event(event)
      mark_notified(notification_key)
      schedule_interview_alerts(event) if interview_event?(event)
    end
  end

  private

  def build_notification_key(event)
    updated_at = event[:updated]&.to_i || 0
    "#{event[:id]}:#{updated_at}"
  end

  def already_notified?(key)
    redis.sismember(NOTIFIED_KEY, key)
  end

  def mark_notified(key)
    redis.sadd(NOTIFIED_KEY, key)
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
