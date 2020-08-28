module ActiveRecord::Base::WithPresenter
  extend ActiveSupport::Concern

  class_methods do
    def presenter_class
      @presenter_class ||= begin
        klass = ActiveSupport::Dependencies.safe_constantize("#{name.camelize}Presenter")
        klass || ActiveSupport::Dependencies.safe_constantize("#{base_class.name.camelize}Presenter")
      end
    end
  end

  def presenter
    @presenter ||= self.class.presenter_class.new(object: self)
  end
end
