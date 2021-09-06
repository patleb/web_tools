module ActiveRecord::Base::WithFile
  extend ActiveSupport::Concern

  # TODO correct :through globally --> record_type is nil
  class_methods do
    def has_one_attached(name, allow_destroy: nil, **options)
      super(name, **options)

      _has_attached_with_destroy(name, allow_destroy, **options) if allow_destroy

      define_method "#{name}_blob" do
        super().rewhere(ActiveStorage::Attachment.table_name => { record_type: ActiveStorage::Attachment.record_types[self.class.name] })
      end
    end

    def has_many_attached(name, allow_destroy: nil, **options)
      super(name, **options)

      _has_attached_with_destroy(name, allow_destroy, **options) if allow_destroy

      define_method "#{name}_blobs" do
        super().rewhere(ActiveStorage::Attachment.table_name => { record_type: ActiveStorage::Attachment.record_types[self.class.name] })
      end
    end

    private

    def _has_attached_with_destroy(name, allow_destroy, dependent: nil, **)
      case allow_destroy
      when true
        remove_name = :"remove_#{name}"
      when String, Symbol
        remove_name = :"#{allow_destroy}_#{name}"
      else
        raise ArgumentError
      end
      attr_accessor remove_name
      case dependent
      when :purge_later, :purge
        after_save{ public_send(name).send(dependent) if public_send(remove_name).to_b }
      else
        before_save{ public_send(name).detach if public_send(remove_name).to_b }
      end
    end
  end
end

ActiveRecord::Base.prepend ActiveRecord::Base::WithFile
