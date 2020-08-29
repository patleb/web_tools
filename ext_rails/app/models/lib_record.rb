class LibRecord < ActiveRecord::Base
  self.abstract_class = true
  self.table_name_prefix = 'lib_'
  self.belongs_to_required_by_default = false
end
