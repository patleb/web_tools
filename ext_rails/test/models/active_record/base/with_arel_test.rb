require './test/rails_helper'

Test::Record.class_eval do
  def self.find_2nd_int_with_related
    relateds = Test::RelatedRecord.alias_table(:relateds)
    even.where(integer: 2)
      .joins(join(relateds).on(column(:id) == relateds[:record_id]).join_sources)
      .select(:id, greatest(:string, :text, relateds[:name], as: :label))
      .take
  end
end

class ActiveRecord::Base::WithArelTest < ActiveSupport::TestCase
  fixtures 'test/records', 'test/related_records'

  test '.column, .alias_table, .join, .greatest' do
    assert_equal 'text-2 Lorem Ipsum', Test::Record.find_2nd_int_with_related.label
  end
end
