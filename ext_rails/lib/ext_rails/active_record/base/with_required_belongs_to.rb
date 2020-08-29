module ActiveRecord::Base::WithRequiredBelongsTo
  extend ActiveSupport::Concern

  class_methods do
    def belongs_to(name, *, **options)
      unless options.has_key?(:optional) || options.has_key?(:required) || belongs_to_required_by_default
        options[:optional] = true
        validates "#{name}_id", presence: true
      end
      super
    end
  end
end
