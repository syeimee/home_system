class InterviewAlertCheckJob < ApplicationJob
  queue_as :default

  SCHEDULED_KEY = 'interview_alerts_scheduled'.freeze

  def perform
    events = GoogleCalendarService.new.upcoming_events
    interview_events = events.select { |e| interview_event?(e) }

    interview_events.each do |event|
      next if already_scheduled?(event)

      schedule_alerts(event)
      mark_scheduled(event)
    end
  end

  private

  def interview_event?(event)
    subject = event[:subject].to_s
    Settings[:interview][:keywords].any? { |kw| subject.downcase.include?(kw.downcase) }
  end

  def schedule_alerts(event)
    start_time = event[:start_time]
    return if start_time.nil? || start_time.past?

    Settings[:interview][:notify_before_minutes].each do |minutes|
      alert_time = start_time - minutes.minutes
      next if alert_time.past?

      AlexaAnnounceJob.set(wait_until: alert_time).perform_later(minutes)
    end
  end

  def already_scheduled?(event)
    redis.sismember(SCHEDULED_KEY, event[:id])
  end

  def mark_scheduled(event)
    redis.sadd(SCHEDULED_KEY, event[:id])
    redis.expire(SCHEDULED_KEY, 24.hours.to_i)
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
  end
end
