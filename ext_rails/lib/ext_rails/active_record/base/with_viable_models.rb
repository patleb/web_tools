module ActiveRecord::Base::WithViableModels
  extend ActiveSupport::Concern

  EXCLUDED_MODEL_SUFFIXES = IceNine.deep_freeze(%w(
    .include.rb
    .prepend.rb
    _admin.rb
    _record.rb
    _decorator.rb
    /current.rb
    /root.rb
    /null.rb
    /base.rb
  ))

  class_methods do
    def viable_models
      @viable_models ||= Rails.viable_names('models', ExtRails.config.excluded_models, EXCLUDED_MODEL_SUFFIXES)
    end

    def polymorphic_parents
      @polymorphic_parents ||= begin
        all = viable_models.each_with_object({}) do |model_name, parents|
          model = begin
            model_name.to_const!
          rescue LoadError
            puts model_name if Rails.env.development?
            next
          end
          next if     model < ::ActiveType::Object
          next unless model < ::ActiveRecord::Base
          next if     model.abstract_class?
          next unless model.connection == connection
          model.reflect_on_all_associations.each do |association|
            if association.options[:polymorphic]
              (parents[model.name] ||= {})[association.name] ||= Set.new
            elsif (as = association.options[:as])
              next if association.through_reflection?
              ((parents[association.klass.name] ||= {})[as.to_sym] ||= Set.new) << model
            end
          end
        end
        all.each_value{ |associations| associations.transform_values!(&:to_a) }
        all
      end
    end
  end
end
