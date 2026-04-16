class OutlookPollingJob < ApplicationJob
  queue_as :default

  REDIS_KEY_PREFIX = 'outlook_synced:'.freeze
  SYNCED_TTL = 30.days.to_i

  def perform
    redis = Redis.new(url: ENV.fetch('REDIS_URL'))
    events = MicrosoftGraphService.new.recent_events
    keywords = Settings[:interview][:keywords]

    events.each do |event|
      next unless interview_event?(event, keywords)
      next if already_synced?(redis, event[:id])

      google_event = GoogleCalendarService.new.create_event(
        title: "【面接】#{event[:subject]}",
        start_time: event[:start_time],
        end_time: event[:end_time]
      )

      mark_synced(redis, event[:id])
      schedule_alexa_announcements(google_event)
    end
  end

  private

  def interview_event?(event, keywords)
    subject = event[:subject].to_s.downcase
    keywords.any? { |kw| subject.include?(kw.downcase) }
  end

  def already_synced?(redis, event_id)
    redis.exists?("#{REDIS_KEY_PREFIX}#{event_id}")
  end

  def mark_synced(redis, event_id)
    redis.set("#{REDIS_KEY_PREFIX}#{event_id}", '1', ex: SYNCED_TTL)
  end

  def schedule_alexa_announcements(event)
    Settings[:interview][:notify_before_minutes].each do |minutes|
      announce_at = event[:start_time] - minutes.minutes
      next if announce_at <= Time.current

      AlexaAnnounceJob.set(wait_until: announce_at).perform_later(minutes)
    end
  end
end
