module ActiveRecord::Base::WithViableModels
  extend ActiveSupport::Concern

  EXCLUDED_MODEL_SUFFIXES = IceNine.deep_freeze(%w(
    .include.rb
    .prepend.rb
    _admin.rb
    _decorator.rb
    /current.rb
    /root.rb
    /null.rb
    /base.rb
    /main.rb
    /relation.rb
  ))

  included do
    self.store_base_sti_class = false
  end

  class_methods do
    def viable_models
      @viable_models ||= Rails.viable_names('models', ExtRails.config.excluded_models, EXCLUDED_MODEL_SUFFIXES)
    end

    def sti_parents
      @sti_parents ||= begin
        all = viable_models.each_with_object({}) do |model_name, parents|
          with_model(model_name) do |model|
            if model.sti? && model.base_class?
              parents[model.name] ||= Set.new(model.inherited_types)
            end
          end
        end
        all.transform_values!(&:to_a)
        all
      end
    end

    def polymorphic_parents
      @polymorphic_parents ||= begin
        all = viable_models.each_with_object({}) do |model_name, parents|
          with_model(model_name) do |model|
            model.reflect_on_all_associations.each do |association|
              if association.options[:polymorphic]
                (parents[model.name] ||= {})[association.name] ||= Set.new
              elsif (as = association.options[:as])
                next if association.through_reflection?
                ((parents[association.klass.name] ||= {})[as.to_sym] ||= Set.new) << model
              end
            end
          end
        end
        all.each_value{ |associations| associations.transform_values!(&:to_a) }
        all
      end
    end

    def sti?
      has_attribute?(inheritance_column)
    end

    def self_and_inherited_types
      [base_class].concat inherited_types
    end

    def inherited_types
      @inherited_types ||= base_class.descendants.reject(&:abstract_class?).select{ |klass| klass.connection == connection }
    end

    private

    def with_model(model_name)
      model = begin
        model_name.to_const!
      rescue LoadError, NameError
        puts model_name if Rails.env.development?
        return
      end
      return if     model < ::ActiveType::Object
      return unless model < ::ActiveRecord::Base
      return if     model.abstract_class?
      return unless model.connection == connection
      yield model
    end
  end
end
