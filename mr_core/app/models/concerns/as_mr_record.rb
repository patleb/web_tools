module AsMrRecord
  extend ActiveSupport::Concern

  included do
    self.table_name_prefix = 'mr_'
  end
end
