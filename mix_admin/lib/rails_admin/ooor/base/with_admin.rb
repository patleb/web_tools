module Ooor::Base::WithAdmin
  extend ActiveSupport::Concern

  class_methods do
    def rails_admin(&block)
      RailsAdmin.model(self, &block)
    end
  end

  def rails_admin_default_object_label_method
    new_record? ? "new #{self.class}" : "#{self.class} ##{id}"
  end

  def safe_send(value)
    if has_attribute?(value)
      attribute(value)
    else
      send(value)
    end
  end
end

Ooor::Base.include Ooor::Base::WithAdmin
