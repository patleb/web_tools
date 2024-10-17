module ActiveRecord::Associations::Builder::HasOne::WithDiscard
  extend ActiveSupport::Concern

  class_methods do
    def build(model, name, scope, options, &block)
      return super unless options[:discardable]
      scope = ->(record) { as_discardable(record) } unless scope
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
