require_relative 'boot'

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'active_job/railtie'

Bundler.require(*Rails.groups)

module HomeSystem
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = 'Asia/Tokyo'
    config.active_job.queue_adapter = :sidekiq
  end
end
