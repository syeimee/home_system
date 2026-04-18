module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      session_key = Rails.application.config.session_options[:key]
      session_data = cookies.encrypted[session_key] || cookies.signed[session_key] || {}
      email = session_data['user_email']
      reject_unauthorized_connection unless email
      email
    end
  end
end
