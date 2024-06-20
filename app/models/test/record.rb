module Test
  class Record < ActiveRecord::Base
    self.table_name_prefix = 'test_'

    scope :even, -> { where('"test_records"."id" % 2 = 0') }
    scope :odd,  -> { invert_where(even) }

    has_many :related_records

    after_discard -> { discard_all! :related_records }
    before_undiscard -> { undiscard_all! :related_records }
  end
end
