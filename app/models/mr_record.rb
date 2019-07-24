class MrRecord < ActiveRecord::Base
  self.abstract_class = true
  self.table_name_prefix = 'mr_'
end
