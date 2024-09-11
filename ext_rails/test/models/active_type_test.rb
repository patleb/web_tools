require './test/test_helper'

class ActiveTypeTest < ActiveSupport::TestCase
  test '.ar_attribute, .enum' do
    record = Test::ObjectRecord.first
    assert_equal 'Name 0', record.name
    assert_equal :simple, record.type
    assert_equal true, record.simple?
    assert_equal false, record.complex?
    assert_equal 12, Test::ObjectRecord.all.simple.size
    assert_equal 0, Test::ObjectRecord.all.complex.size
    assert_equal({ 'type' => { simple: 0, complex: 1 } }, Test::ObjectRecord.defined_enums)
  end
end
