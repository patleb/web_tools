module ActiveRecord::Base::WithAdmin
  extend ActiveSupport::Concern

  included do
    class_attribute :rails_admin_blocks
  end

  class_methods do
    def inherited(subclass)
      super
      if (model_name = subclass.name)
        admin_module = ActiveSupport::Dependencies.safe_constantize('Admin')
        admin_concern = "#{model_name}Admin".safe_constantize
        if admin_concern
          subclass.include admin_module if admin_module
          subclass.include admin_concern
        end
      end
    end

    def rails_admin(&block)
      (self.rails_admin_blocks ||= Set.new) << block
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
