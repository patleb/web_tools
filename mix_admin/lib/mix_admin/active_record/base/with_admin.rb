module ActiveRecord::Base::WithAdmin
  extend ActiveSupport::Concern

  class_methods do
    delegate :viewable_url, :allowed_url, to: :admin_model

    def admin_model
      return @admin_model if defined? @admin_model
      klass = (klass_name = "Admin::#{name}Presenter").to_const
      klass ||= "Admin::#{superclass.name}Presenter".to_const
      klass ||= "Admin::#{base_class.name}Presenter".to_const
      @admin_model = klass && presenter_subclass(klass, klass_name, Admin)
    end

    def admin_label(count = nil)
      if count && (Current.locale == :fr ? count > 1 : count != 1)
        admin_label_plural
      else
        (@admin_label ||= {})[Current.locale] ||= model_name.human
      end
    end

    def admin_label_plural
      (@admin_label_plural ||= {})[Current.locale] ||= begin
        label = admin_label
        if label != (label_plural = model_name.human(count: Float::INFINITY, default: label))
          label_plural
        else
          label.pluralize(Current.locale)
        end
      end
    end
  end

  included do
    delegate :admin_model, to: :class
    delegate :viewable_url, :allowed_url, to: :admin_presenter
  end

  def admin_presenter
    @admin_presenter ||= admin_model.new(record: self)
  end

  def admin_label
    "#{self.class.admin_label} ##{public_send(admin_model.primary_key)}"
  end
end

ActiveRecord::Base.include ActiveRecord::Base::WithAdmin
