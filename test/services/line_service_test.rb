require 'test_helper'

class LineServiceTest < ActiveSupport::TestCase
  test 'notify_event sends formatted message to LINE group' do
    event = {
      subject: '歯医者の予約',
      start_time: Time.zone.parse('2026-05-10 14:00')
    }

    Line::Bot::V2::MessagingApi::ApiClient.any_instance
                                          .expects(:push_message)
                                          .with do |kwargs|
                                            req = kwargs[:push_message_request]
                                            req.to == Settings[:line][:group_id] &&
                                              req.messages.first.text.include?('歯医者の予約') &&
                                              req.messages.first.text.include?('2026/05/10 14:00')
                                          end
      .once

    service = LineService.new
    service.notify_event(event)
  end
end
