module ActiveRecord::Associations::Builder::HasMany::WithDiscard
  extend ActiveSupport::Concern

  class_methods do
    def build(model, name, scope, options, &block)
      return super unless options[:discardable]
      scope = ->(record) { record.discarded ? with_discarded : all } unless scope
      reflection = super
      model.after_discard -> { discard_all! name }
      model.before_undiscard -> { undiscard_all! name }
      reflection
    end

    private

    def valid_options(options)
      super + [:discardable]
    end
  end
end

ActiveRecord::Associations::Builder::HasMany.include ActiveRecord::Associations::Builder::HasMany::WithDiscard
