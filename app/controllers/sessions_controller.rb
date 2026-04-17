class SessionsController < ApplicationController
  def new; end

  def create
    auth = request.env['omniauth.auth']
    email = auth.dig('info', 'email')

    unless email == Settings[:app][:allowed_email]
      redirect_to login_path, alert: '許可されていないアカウントです'
      return
    end

    # Google refresh token を Redis に保存
    refresh_token = auth.dig('credentials', 'refresh_token')
    TokenStore.new.save_google_refresh_token(refresh_token) if refresh_token

    session[:user_email] = email
    session[:user_name] = auth.dig('info', 'name')
    redirect_to dashboard_path, notice: 'ログインしました'
  end

  def destroy
    reset_session
    redirect_to login_path, notice: 'ログアウトしました'
  end

  def failure
    redirect_to login_path, alert: "認証に失敗しました: #{params[:message]}"
  end

  def mock_login
    return head(:not_found) unless Rails.env.test?

    session[:user_email] = params[:email]
    head :ok
  end
end
