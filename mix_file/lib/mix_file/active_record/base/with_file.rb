MonkeyPatch.add{['activestorage', 'lib/active_storage/reflection.rb', 'c22d50cfe01f808b6a8b5171daa161b1e4190a9b0277fec18a0e64eac383a4b2']}

module ActiveRecord::Base::WithFile
  extend ActiveSupport::Concern

  prepended do
    class_attribute :attachment_reflections, instance_writer: false, default: {}.with_indifferent_access
  end

  class_methods do
    def has_one_attached(name, ...)
      super

      define_method "#{name}_blob" do
        super().rewhere(ActiveStorage::Attachment.table_name => { record_type: ActiveStorage::Attachment.record_types[self.class.name] })
      end
    end

    def has_many_attached(name, ...)
      super

      define_method "#{name}_blobs" do
        super().rewhere(ActiveStorage::Attachment.table_name => { record_type: ActiveStorage::Attachment.record_types[self.class.name] })
      end
    end
  end
end

ActiveRecord::Base.prepend ActiveRecord::Base::WithFile
