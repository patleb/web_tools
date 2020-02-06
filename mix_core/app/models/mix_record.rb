class MixRecord < ActiveRecord::Base
  self.abstract_class = true
  self.table_name_prefix = 'mix_'
end
