Rails.application.config.session_store :redis_session_store,
                                       key: '_home_system_session',
                                       redis: {
                                         expire_after: 7.days,
                                         key_prefix: 'home_system:session:',
                                         url: ENV.fetch('REDIS_URL', 'redis://localhost:6379')
                                       }
