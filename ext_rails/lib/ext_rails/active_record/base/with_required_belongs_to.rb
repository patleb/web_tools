MonkeyPatch.add{['activerecord', 'lib/active_record/associations/builder/belongs_to.rb', '7bd76bcf3d7a4927db3fd82e20eacd4a2f60c122a41683a717ac9ff25b0b3924']}

module ActiveRecord::Base::WithRequiredBelongsTo
  extend ActiveSupport::Concern

  class_methods do
    def belongs_to(name, *, **options)
      unless options.has_key?(:optional) || options.has_key?(:required) || belongs_to_required_by_default
        options[:optional] = true
        validates options[:foreign_key] || "#{name}_id", presence: true
      end
      super
    end
  end
end
