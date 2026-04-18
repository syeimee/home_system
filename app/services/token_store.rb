class TokenStore
  def initialize
    @redis = Redis.new(url: ENV.fetch('REDIS_URL'))
  end

  def google_refresh_token
    decrypt(@redis.get('token:google_refresh_token'))
  end

  def save_google_refresh_token(token)
    @redis.set('token:google_refresh_token', encrypt(token))
  end

  private

  def encryptor
    key = ActiveSupport::KeyGenerator.new(ENV.fetch('SECRET_KEY_BASE')).generate_key('token_store', 32)
    ActiveSupport::MessageEncryptor.new(key)
  end

  def encrypt(value)
    return nil unless value

    encryptor.encrypt_and_sign(value)
  end

  def decrypt(value)
    return nil unless value

    encryptor.decrypt_and_verify(value)
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
    value
  end
end
