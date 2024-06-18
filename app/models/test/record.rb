module Test
  class Record < ActiveRecord::Base
    self.table_name_prefix = 'test_'

    scope :even,  -> { where('"test_records"."id" % 2 = 0') }
    scope :today, -> { where(date: Time.current.beginning_of_day..Time.current.end_of_day) }

    def self.find_second_with_related
      relateds = RelatedRecord.alias_table(:relateds)
      even.where(integer: 2)
        .joins(join(relateds).on(column(:id) == relateds[:record_id]).join_sources)
        .select(:id, greatest(:string, :text, relateds[:name], as: :label))
        .first
    end
  end
end
