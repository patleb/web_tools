require './test/spec_helper'

class UUIDTest < Minitest::TestCase
  test '#shorten, #expand' do
    uuid = SecureRandom.uuid
    short = UUID.shorten(uuid)
    assert_match UUID::BASE_VALID, short
    assert short.size < uuid.size
    assert_equal uuid, UUID.expand(short)
  end
end
