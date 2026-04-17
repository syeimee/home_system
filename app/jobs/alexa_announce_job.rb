class AlexaAnnounceJob < ApplicationJob
  queue_as :default

  def perform(minutes_before)
    message = Settings[:alexa][:"message_#{minutes_before}"]
    return unless message

    AlexaService.new.announce(message:)
  end
end
