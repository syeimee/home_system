class MsAuthController < ApplicationController
  before_action :require_login

  def authorize
    params_hash = {
      client_id: ENV.fetch('MS_CLIENT_ID'),
      response_type: 'code',
      redirect_uri: ms_redirect_uri,
      scope: 'offline_access Calendars.Read',
      response_mode: 'query'
    }
    redirect_to "https://login.microsoftonline.com/#{ENV.fetch('MS_TENANT_ID')}/oauth2/v2.0/authorize?#{params_hash.to_query}",
                allow_other_host: true
  end

  def callback
    Rails.logger.info "MS OAuth callback params: #{request.query_string}"

    response = HTTParty.post(
      "https://login.microsoftonline.com/#{ENV.fetch('MS_TENANT_ID')}/oauth2/v2.0/token",
      body: {
        client_id: ENV.fetch('MS_CLIENT_ID'),
        client_secret: ENV.fetch('MS_CLIENT_SECRET'),
        code: request.params['code'],
        redirect_uri: ms_redirect_uri,
        grant_type: 'authorization_code',
        scope: 'offline_access Calendars.Read'
      }
    )

    data = response.parsed_response

    if data['refresh_token']
      TokenStore.new.save_ms_refresh_token(data['refresh_token'])
      redirect_to dashboard_path, notice: 'Microsoft アカウントを連携しました'
    else
      redirect_to dashboard_path, alert: "Microsoft 連携に失敗しました: #{data['error_description']}"
    end
  end

  private

  def ms_redirect_uri
    "#{Settings[:app][:webhook_url]}/auth/microsoft/callback"
  end
end
