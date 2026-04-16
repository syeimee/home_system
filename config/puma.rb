threads_count = ENV.fetch('RAILS_MAX_THREADS', 3)
threads 1, threads_count

port ENV.fetch('PORT', 3000)

environment ENV.fetch('RAILS_ENV', 'development')

workers ENV.fetch('WEB_CONCURRENCY', 1)

preload_app!

plugin :tmp_restart
