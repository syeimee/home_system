require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'GET /login renders login page' do
    get login_path

    assert_response :success
  end

  test 'DELETE /logout clears session and redirects' do
    delete logout_path

    assert_redirected_to login_path
  end
end
