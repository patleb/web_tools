module AsLibRecord
  extend ActiveSupport::Concern

  included do
    self.table_name_prefix = 'lib_'
  end
end
