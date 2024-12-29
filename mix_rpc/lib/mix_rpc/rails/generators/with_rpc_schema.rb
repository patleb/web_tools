MonkeyPatch.add{['railties', 'lib/rails/generators/migration.rb', '6ab4152c1009d337395253661604550982f69d40db3678cf5cc68982edbc1fef']}

if defined? Rails::Generators
  module Rails::Generators::WithRpcSchema
    extend ActiveSupport::Concern

    class_methods do
      def find_by_namespace(name, *)
        return super unless name == 'migration'
        result = super
        require 'mix_rpc/rails/generators/migration/with_rpc_schema'
        result
      end
    end
  end

  Rails::Generators.prepend Rails::Generators::WithRpcSchema
end
