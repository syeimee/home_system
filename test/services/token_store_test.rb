require 'test_helper'

class TokenStoreTest < ActiveSupport::TestCase
  setup do
    @redis = mock('redis')
    Redis.stubs(:new).returns(@redis)
    @store = TokenStore.new
  end

  test 'save_google_refresh_token encrypts and stores token in Redis' do
    @redis.expects(:set).with('token:google_refresh_token', anything)
    @store.save_google_refresh_token('test-token')
  end

  test 'google_refresh_token decrypts token from Redis' do
    # Encrypt a value first to get the expected ciphertext
    key = ActiveSupport::KeyGenerator.new(ENV.fetch('SECRET_KEY_BASE')).generate_key('token_store', 32)
    enc = ActiveSupport::MessageEncryptor.new(key)
    encrypted = enc.encrypt_and_sign('my-secret-token')

    @redis.expects(:get).with('token:google_refresh_token').returns(encrypted)

    assert_equal 'my-secret-token', @store.google_refresh_token
  end

  test 'google_refresh_token returns plaintext if not encrypted (migration)' do
    @redis.expects(:get).with('token:google_refresh_token').returns('plain-token')

    assert_equal 'plain-token', @store.google_refresh_token
  end
end
