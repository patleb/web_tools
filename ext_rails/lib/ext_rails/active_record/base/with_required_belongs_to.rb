MonkeyPatch.add{['activerecord', 'lib/active_record/associations/builder/belongs_to.rb', '7bd76bcf3d7a4927db3fd82e20eacd4a2f60c122a41683a717ac9ff25b0b3924']}

module ActiveRecord::Base::WithRequiredBelongsTo
  extend ActiveSupport::Concern

  class_methods do
    def belongs_to(name, *, **options)
      unless options.has_key?(:optional) || options.has_key?(:required) || belongs_to_required_by_default
        options[:optional] = true
        Array.wrap(options[:foreign_key] || options[:query_constraints] || "#{name}_id").each do |foreign_key|
          foreign_key = foreign_key.to_sym
          next_foreign_key = false
          reflect_on_all_associations.each do |association|
            next unless association.belongs_to?
            break (next_foreign_key = true) if association.foreign_key.to_sym == foreign_key
          end
          validates foreign_key, presence: true unless next_foreign_key
        end
      end
      super
    end
  end
end
