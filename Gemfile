source 'https://rubygems.org'

gem 'propshaft'
gem 'puma', '>= 5.0'
gem 'rails', '~> 8.0'

# Redis / Sidekiq
gem 'redis', '>= 4.0.1'
gem 'sidekiq', '~> 7.0'

# Authentication
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'redis-session-store'

# External APIs
gem 'google-apis-calendar_v3'
gem 'googleauth'
gem 'httparty'
gem 'line-bot-api'

# Timezone
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'mocha'
  gem 'rubocop', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-rails', require: false
  gem 'webmock'
end

group :development do
  gem 'web-console'
end
