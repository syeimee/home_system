class AlexaAnnounceJob < ApplicationJob
  queue_as :default

  def perform(minutes_before)
    message = Settings[:alexa][:"message_#{minutes_before}"]
    unless message
      Rails.logger.warn "[AlexaAnnounce] No message for #{minutes_before} minutes"
      return
    end

    Rails.logger.info "[AlexaAnnounce] Announcing: #{message}"
    response = AlexaService.new.announce(message:)
    Rails.logger.info "[AlexaAnnounce] Response: #{response.code}"
  rescue => e
    Rails.logger.error "[AlexaAnnounce] Error: #{e.class} - #{e.message}"
    raise
  end
end
