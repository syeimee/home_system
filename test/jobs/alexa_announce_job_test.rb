require 'test_helper'

class AlexaAnnounceJobTest < ActiveSupport::TestCase
  test 'perform announces to all Alexa devices' do
    VoicemonkeyService.any_instance
                      .expects(:announce)
                      .with(device: 'living-room-echo', message: Settings[:alexa][:message_15])
                      .once

    VoicemonkeyService.any_instance
                      .expects(:announce)
                      .with(device: 'bedroom-echo', message: Settings[:alexa][:message_15])
                      .once

    AlexaAnnounceJob.perform_now(15)
  end

  test 'perform does nothing for unknown minutes' do
    VoicemonkeyService.any_instance.expects(:announce).never
    AlexaAnnounceJob.perform_now(99)
  end
end
