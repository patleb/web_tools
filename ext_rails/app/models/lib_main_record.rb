class LibMainRecord < ActiveRecord::Main
  self.abstract_class = true
  self.table_name_prefix = 'lib_'
end
