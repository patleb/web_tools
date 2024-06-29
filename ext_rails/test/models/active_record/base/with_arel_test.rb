require './test/rails_helper'

Test::Record.class_eval do
  def self.first_odd_with_related
    r = Test::RelatedRecord.alias_table(:r)
    odd.where(integer: 1)
      .joins(join(r).on(column(:id) == r[:record_id]).join_sources)
      .select(:id, greatest(:string, :text, r[:name], as: :label))
      .take
  end
end

class ActiveRecord::Base::WithArelTest < ActiveSupport::TestCase
  fixtures 'test/records', 'test/related_records'

  test '.column, .alias_table, .join, .greatest' do
    assert_equal 'text-1 Lorem Ipsum', Test::Record.first_odd_with_related.label
  end
end
