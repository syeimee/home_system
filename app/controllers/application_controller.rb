class ApplicationController < ActionController::Base
  private

  def require_login
    return if session[:user_email]

    redirect_to login_path, alert: 'ログインしてください'
  end

  def current_user_email
    session[:user_email]
  end
  helper_method :current_user_email
end
