module ActiveRecord::Base::WithPresenter
  extend ActiveSupport::Concern

  class_methods do
    def presenter_class
      @presenter_class ||= begin
        klass = "#{name.camelize}Presenter".to_const
        klass || "#{base_class.name.camelize}Presenter".to_const!
      end
    end
  end

  def presenter
    @presenter ||= self.class.presenter_class.new(object: self)
  end
end
