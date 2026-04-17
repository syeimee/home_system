class TokenStore
  PREFIX = 'token:'.freeze

  def initialize
    @redis = Redis.new(url: ENV.fetch('REDIS_URL'))
  end

  def save(key, value)
    @redis.set("#{PREFIX}#{key}", value)
  end

  def fetch(key)
    @redis.get("#{PREFIX}#{key}")
  end

  def google_refresh_token
    fetch('google_refresh_token')
  end

  def save_google_refresh_token(token)
    save('google_refresh_token', token)
  end

  def ms_refresh_token
    fetch('ms_refresh_token')
  end

  def save_ms_refresh_token(token)
    save('ms_refresh_token', token)
  end
end
