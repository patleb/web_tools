module AsMixRecord
  extend ActiveSupport::Concern

  included do
    self.table_name_prefix = 'mix_'
  end
end
