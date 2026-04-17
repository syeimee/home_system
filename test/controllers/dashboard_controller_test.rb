require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test 'GET /dashboard redirects to login when not authenticated' do
    get dashboard_path

    assert_redirected_to login_path
  end

  test 'GET /dashboard renders when authenticated' do
    login_as_allowed_user
    SwitchbotService.any_instance.stubs(:devices).returns([])
    get dashboard_path

    assert_response :success
  end

  test 'POST device_on redirects to login when not authenticated' do
    post device_on_path('device-id-1')

    assert_redirected_to login_path
  end

  test 'POST device_on calls SwitchbotService and redirects' do
    login_as_allowed_user
    SwitchbotService.any_instance.expects(:command).with('device-id-1', 'turnOn').once
    post device_on_path('device-id-1')

    assert_redirected_to dashboard_path
  end

  test 'POST device_off calls SwitchbotService and redirects' do
    login_as_allowed_user
    SwitchbotService.any_instance.expects(:command).with('device-id-1', 'turnOff').once
    post device_off_path('device-id-1')

    assert_redirected_to dashboard_path
  end

  private

  def login_as_allowed_user
    post '/mock_login', params: { email: Settings[:app][:allowed_email] }
  end
end
