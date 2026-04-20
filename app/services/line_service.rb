require 'line-bot-api'

class LineService
  def initialize
    @client = Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV.fetch('LINE_CHANNEL_TOKEN')
    )
  end

  def notify_event(event)
    message = Line::Bot::V2::MessagingApi::TextMessage.new(
      type: 'text',
      text: format_message(event)
    )
    request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
      to: Settings[:line][:group_id],
      messages: [message]
    )
    @client.push_message(push_message_request: request)
  end

  private

  def format_message(event)
    time_str = if event[:all_day]
                 event[:start_time].strftime('%Y/%m/%d') + ' 終日'
               else
                 event[:start_time].strftime('%Y/%m/%d %H:%M')
               end
    <<~MSG.strip
      📅 予定が追加されました
      タイトル: #{event[:subject]}
      日時: #{time_str}
    MSG
  end
end
