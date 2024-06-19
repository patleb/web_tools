module Test
  class Record < ActiveRecord::Base
    self.table_name_prefix = 'test_'

    scope :even,  -> { where('"test_records"."id" % 2 = 0') }
    scope :odd,   -> { invert_where(even) }
    scope :today, -> { where(date: Time.current.beginning_of_day..Time.current.end_of_day) }
  end
end
