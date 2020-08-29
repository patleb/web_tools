module ActionController::Base::WithPresenter
  extend ActiveSupport::Concern

  included do
    attr_accessor :template_virtual_path
    helper_method :template_virtual_path, :presenter_class
  end

  def presenter_class
    name = template_virtual_path&.camelize
    klass = name && "#{name}Presenter".to_const
    klass || "#{current_layout.camelize}Presenter".to_const
  end
end
