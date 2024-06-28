require './test/rails_helper'

class ActiveRecord::Base::WithNullifyBlanksTest < ActiveSupport::TestCase
  fixtures 'test/records'

  test '#nullify_blanks' do
    record = Test::Record.find(1)
    assert_nil record.password
    assert_equal '', record.attribute_in_database(:password)
    assert_equal 'string-1', record.string
    record.update! string: ''
    assert_nil record.attribute_in_database(:password)
    assert_nil record.string
    assert_equal 'string-1', record.attribute_before_last_save(:string)
  end
end
