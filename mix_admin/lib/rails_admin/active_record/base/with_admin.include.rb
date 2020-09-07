module ActiveRecord::Base::WithAdmin
  extend ActiveSupport::Concern

  class_methods do
    def rails_admin_blocks
      @rails_admin_blocks
    end

    def inherited(subclass)
      super
      if (model_name = subclass.name)
        unless subclass.base_class?
          base_admin_concern = "#{subclass.base_class.name}Admin".to_const
          if base_admin_concern
            subclass.base_class.rails_admin_blocks.each{ |block| subclass.rails_admin(&block) }
          end
        end
        admin_concern = "#{model_name}Admin".to_const
        if admin_concern
          subclass.include admin_concern
        end
      end
    end

    def rails_admin(&block)
      (@rails_admin_blocks ||= Set.new) << block
      RailsAdmin.model(self, &block)
    end
  end

  def rails_admin_default_object_label_method
    new_record? ? "new #{self.class}" : "#{self.class} ##{id}"
  end

  def safe_send(value)
    if has_attribute?(value)
      self[value]
    else
      send(value)
    end
  end
end
