Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  # Authentication
  get 'login', to: 'sessions#new'
  get 'auth/google_oauth2/callback', to: 'sessions#create'
  get 'auth/failure', to: 'sessions#failure'
  delete 'logout', to: 'sessions#destroy'

  # Dashboard
  get 'dashboard', to: 'dashboard#index'
  post 'dashboard/devices/:id/on', to: 'dashboard#device_on', as: :device_on
  post 'dashboard/devices/:id/off', to: 'dashboard#device_off', as: :device_off

  # Webhooks
  namespace :webhooks do
    post 'google', to: 'google#create'
    post 'switchbot', to: 'switchbot#create'
  end

  # Test-only route for simulating login
  post 'mock_login', to: 'sessions#mock_login' if Rails.env.test?

  root 'sessions#new'
end
