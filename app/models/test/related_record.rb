module Test
  class RelatedRecord < ActiveRecord::Base
    self.table_name_prefix = 'test_'

    belongs_to :record
  end
end
