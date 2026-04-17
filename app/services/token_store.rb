class TokenStore
  def initialize
    @redis = Redis.new(url: ENV.fetch('REDIS_URL'))
  end

  def google_refresh_token
    @redis.get('token:google_refresh_token')
  end

  def save_google_refresh_token(token)
    @redis.set('token:google_refresh_token', token)
  end
end
