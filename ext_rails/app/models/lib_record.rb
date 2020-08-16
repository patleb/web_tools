class LibRecord < ActiveRecord::Base
  self.abstract_class = true
  self.table_name_prefix = 'lib_'
end
