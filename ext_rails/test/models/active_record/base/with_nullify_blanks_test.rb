require './test/test_helper'

class ActiveRecord::Base::WithNullifyBlanksTest < ActiveSupport::TestCase
  fixtures 'test/records'

  test '#nullify_blanks' do
    record = Test::Record.find(1)
    assert_nil record.password
    assert_equal '', record.attribute_in_database(:password)
    assert_equal 'text-1 Lorem Ipsum', record.text
    record.update! text: ''
    assert_nil record.attribute_in_database(:password)
    assert_nil record.text
    assert_equal 'text-1 Lorem Ipsum', record.attribute_before_last_save(:text)
  end
end
