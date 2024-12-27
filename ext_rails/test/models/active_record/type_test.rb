require './test/test_helper'

class ActiveRecord::TypeTest < ActiveSupport::TestCase
  fixtures 'test/records'

  let(:record){ Test::Record.find(1) }

  it 'should deserialize as hash with keyword access' do
    assert_equal HashWithKeywordAccess, record.json.class
    assert_equal 1, record.json[:int]
  end

  it 'should encrypt/decrypt value' do
    assert record.secret.start_with? Setting::SECRET
    assert_equal 'test', record.decrypted('secret')
  end
end
