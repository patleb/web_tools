module ActionController::Base::WithPresenter
  extend ActiveSupport::Concern

  included do
    class_attribute :default_presenter_name
    attr_accessor :template_virtual_path
    helper_method :presenter_class
  end

  def presenter_class
    name = template_virtual_path&.camelize
    klass = name && ActiveSupport::Dependencies.safe_constantize("#{name}Presenter")
    klass || default_presenter_name && ActiveSupport::Dependencies.safe_constantize(default_presenter_name)
  end
end
