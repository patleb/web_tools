module ActiveRecord::Base::WithAdmin
  extend ActiveSupport::Concern

  class_methods do
    delegate :viewable_url, :allowed_url, to: :admin_model

    def admin_model
      @admin_model ||= begin
        klass = (klass_name = "Admin::#{name}Presenter").to_const
        klass ||= "Admin::#{superclass.name}Presenter".to_const
        klass ||= "Admin::#{base_class.name}Presenter".to_const!
        if klass.name != klass_name
          klass_name.clear_const
          subclass = Class.new(klass)
          parent = name.deconstantize.split('::').reduce(Admin){ |parent, module_name| parent.const_get(module_name) }
          parent.const_set(klass_name.demodulize, subclass)
          ActiveSupport.run_load_hooks(subclass.name, subclass)
          subclass
        else
          klass
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
    "#{model_name.human} ##{public_send(self.class.primary_key)}"
  end
end

ActiveRecord::Base.include ActiveRecord::Base::WithAdmin
