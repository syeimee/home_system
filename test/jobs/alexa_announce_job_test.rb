require 'test_helper'

class AlexaAnnounceJobTest < ActiveSupport::TestCase
  test 'perform announces via AlexaService' do
    AlexaService.any_instance
                .expects(:announce)
                .with(message: Settings[:alexa][:message_15])
                .once

    AlexaAnnounceJob.perform_now(15)
  end

  test 'perform does nothing for unknown minutes' do
    AlexaService.any_instance.expects(:announce).never
    AlexaAnnounceJob.perform_now(99)
  end
end
