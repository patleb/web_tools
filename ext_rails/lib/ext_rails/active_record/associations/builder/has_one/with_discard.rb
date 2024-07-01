module ActiveRecord::Associations::Builder::HasOne::WithDiscard
  extend ActiveSupport::Concern

  class_methods do
    def build(model, name, scope, options, &block)
      return super unless options[:discardable]
      scope = if scope
        ->(record) { record.discarded ? scope.with_discarded : scope }
      else
        ->(record) { record.discarded ? with_discarded : all }
      end
      reflection = super
      model.after_discard -> { public_send(name).discard! }
      model.before_undiscard -> { public_send(name).undiscard! }
      reflection
    end

    private

    def valid_options(options)
      super + [:discardable]
    end
  end
end

ActiveRecord::Associations::Builder::HasOne.include ActiveRecord::Associations::Builder::HasOne::WithDiscard
