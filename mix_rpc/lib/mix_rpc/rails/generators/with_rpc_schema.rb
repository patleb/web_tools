if defined? Rails::Generators
  module Rails::Generators::WithRpcSchema
    extend ActiveSupport::Concern

    class_methods do
      def find_by_namespace(name, *)
        return super unless name == 'migration'
        result = super
        require 'mix_rpc/active_record/generators/migration_generator/with_rpc_schema'
        result
      end
    end
  end

  Rails::Generators.prepend Rails::Generators::WithRpcSchema
end
