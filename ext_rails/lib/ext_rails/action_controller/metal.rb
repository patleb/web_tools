require_dir __FILE__, 'metal'

ActionController::Metal.class_eval do
  def self.metal_parent?
    superclass == ActionController::Metal
  end

  def self.metal_grandparent?
    superclass.superclass == ActionController::Metal
  end
end

module ActionController::WithExtRails
  extend ActiveSupport::Concern

  prepended do
    class_attribute :local

    include ActiveSupport::LazyLoadHooks::Autorun
    include ActionController::Redirecting::WithStringUrl
    include ActionController::WithContext
    include ActionController::WithMemoization
  end

  class_methods do
    def inherited(subclass)
      super
      if subclass.metal_grandparent?
        subclass.include ActionController::WithStatus
      end
    end
  end
end
