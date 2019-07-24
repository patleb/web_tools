module ActiveRecord::Base::WithInheritedTypes
  extend ActiveSupport::Concern

  included do
    self.store_base_sti_class = false
  end

  class_methods do
    def self_and_inherited_types
      [base_class].concat inherited_types
    end

    def inherited_types
      @inherited_types ||= base_class.descendants.reject(&:abstract_class?).select{ |klass| klass.connection == connection }
    end
  end
end
