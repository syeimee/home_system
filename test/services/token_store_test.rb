require 'test_helper'

class TokenStoreTest < ActiveSupport::TestCase
  setup do
    @redis = mock('redis')
    Redis.stubs(:new).returns(@redis)
    @store = TokenStore.new
  end

  test 'save_google_refresh_token stores token in Redis' do
    @redis.expects(:set).with('token:google_refresh_token', 'test-token')
    @store.save_google_refresh_token('test-token')
  end

  test 'google_refresh_token reads token from Redis' do
    @redis.expects(:get).with('token:google_refresh_token').returns('stored-token')

    assert_equal 'stored-token', @store.google_refresh_token
  end

  test 'save_ms_refresh_token stores token in Redis' do
    @redis.expects(:set).with('token:ms_refresh_token', 'ms-test-token')
    @store.save_ms_refresh_token('ms-test-token')
  end

  test 'ms_refresh_token reads token from Redis' do
    @redis.expects(:get).with('token:ms_refresh_token').returns('ms-stored-token')

    assert_equal 'ms-stored-token', @store.ms_refresh_token
  end
end
