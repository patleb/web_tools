MonkeyPatch.add{['activerecord', 'lib/active_record/associations/builder/singular_association.rb', '1c82c4fc4f087d25a00788db3704af86771d55985babae4a19ba96a05d236319']}

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
      mixin.define_method "#{name}_global_id" do
        public_send(name).to_global_id
      end

      mixin.define_method "#{name}_global_id=" do |global_id|
        public_send("#{name}=", global_id.present? ? GlobalID::Locator.locate(global_id) : nil)
      end
    end
  end
end

ActiveRecord::Associations::Builder::BelongsTo.include ActiveRecord::Associations::Builder::BelongsTo::WithGlobalId
