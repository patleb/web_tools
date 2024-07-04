require './test/rails_helper'

Test::RelatedRecord.class_eval do
  clear_validators!
end

class ActiveRecord::Base::WithRescuableValidationsTest < ActiveSupport::TestCase
  fixtures 'test/records', 'test/related_records'

  test '#_handle_columns_exception, #_handle_base_exception' do
    record = Test::RelatedRecord.create(id: 1, name: 'related to 1', record_id: 1)
    assert_equal({ id: :taken }, record.errors.map{ |e| [e.attribute, e.type] }.to_h)

    record = Test::RelatedRecord.create(name: 'related to 1')
    assert_equal({ record_id: :blank }, record.errors.map{ |e| [e.attribute, e.type] }.to_h)

    record = Test::RelatedRecord.create(name: 'related to 1', record_id: -1)
    assert_equal({ record_id: :required }, record.errors.map{ |e| [e.attribute, e.type] }.to_h)

    record = Test::Record.create(string: '0123456789' * 6)
    assert_equal({ base: :too_long }, record.errors.map{ |e| [e.attribute, e.type] }.to_h)
  end
end
