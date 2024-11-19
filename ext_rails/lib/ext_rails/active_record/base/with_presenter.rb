module ActiveRecord::Base::WithPresenter
  extend ActiveSupport::Concern

  class_methods do
    def presenter_class
      @presenter_class ||= begin
        klass = (klass_name = "#{name.camelize}Presenter").to_const
        klass ||= "#{superclass.name.camelize}Presenter".to_const
        klass ||= "#{base_class.name.camelize}Presenter".to_const!
        presenter_subclass(klass, klass_name)
      end
    end

    private

    def presenter_subclass(klass, klass_name, scope = Object)
      if klass.name != klass_name
        klass_name.clear_const
        subclass = Class.new(klass)
        parent = name.deconstantize.split('::').reduce(scope){ |parent, module_name| parent.const_get(module_name) }
        parent.const_set(klass_name.demodulize, subclass)
        ActiveSupport.run_load_hooks(subclass.name, subclass)
        subclass
      else
        klass
      end
    end
  end

  included do
    delegate :presenter_class, to: :class
    delegate :render, to: :presenter
  end

  def presenter
    @presenter ||= presenter_class.new(record: self)
  end
end
