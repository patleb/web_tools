module ActiveRecord::Associations::Builder::BelongsTo::WithGlobalId
  extend ActiveSupport::Concern

  class_methods do
    private

    def define_accessors(model, reflection)
      super
      if reflection.options[:polymorphic]
        mixin = model.generated_association_methods
        define_global_id_methods(mixin, reflection.name)
      end
    end

    def define_global_id_methods(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_global_id
          #{name}.try(:to_global_id)
        end

        def #{name}_global_id=(global_id)
          self.#{name} = GlobalID::Locator.locate(global_id) if global_id.present?
        end
      CODE
    end
  end
end

ActiveRecord::Associations::Builder::BelongsTo.include ActiveRecord::Associations::Builder::BelongsTo::WithGlobalId
