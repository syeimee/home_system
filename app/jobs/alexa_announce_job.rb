class AlexaAnnounceJob < ApplicationJob
  queue_as :default

  def perform(minutes_before)
    message = Settings[:alexa][:"message_#{minutes_before}"]
    return unless message

    voicemonkey = VoicemonkeyService.new
    Settings[:alexa][:devices].each do |device|
      voicemonkey.announce(device:, message:)
    end
  end
end
