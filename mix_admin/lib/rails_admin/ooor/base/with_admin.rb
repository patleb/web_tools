module Ooor::Base::WithAdmin
  extend ActiveSupport::Concern

  class_methods do
    def rails_admin(&block)
      RailsAdmin.model(self, &block)
    end
  end

  def rails_admin_object_label
    new_record? ? "#{I18n.t('admin.misc.new')} #{model_name.human}" : "#{model_name.human} ##{id}"
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
