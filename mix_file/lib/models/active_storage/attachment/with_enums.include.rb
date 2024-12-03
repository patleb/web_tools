module ActiveStorage::Attachment::WithEnums
  extend ActiveSupport::Concern

  included do
    enum! record_type: MixFile.config.available_records
    enum! name: MixFile.config.available_associations
  end
end
