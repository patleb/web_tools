module ActiveStorage::Record::WithMainRecord
  extend ActiveSupport::Concern

  included do
    include AsMainRecord
  end
end
