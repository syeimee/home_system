class OutlookSyncJob < ApplicationJob
  queue_as :webhooks

  def perform
    events = MicrosoftGraphService.new.recent_events
    keywords = Settings[:interview][:keywords]

    events.each do |event|
      next unless interview_event?(event, keywords)

      google_event = GoogleCalendarService.new.create_event(
        title: "【面接】#{event[:subject]}",
        start_time: event[:start_time],
        end_time: event[:end_time]
      )

      schedule_alexa_announcements(google_event)
    end
  end

  private

  def interview_event?(event, keywords)
    subject = event[:subject].to_s.downcase
    keywords.any? { |kw| subject.include?(kw.downcase) }
  end

  def schedule_alexa_announcements(event)
    Settings[:interview][:notify_before_minutes].each do |minutes|
      announce_at = event[:start_time] - minutes.minutes
      AlexaAnnounceJob.set(wait_until: announce_at).perform_later(minutes)
    end
  end
end
