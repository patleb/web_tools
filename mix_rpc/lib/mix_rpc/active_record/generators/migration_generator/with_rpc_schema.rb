module Rails
  module Generators
    module Migration::WithRpcSchema
      extend ActiveSupport::Concern

      included do
        no_tasks do
          def self.current_migration_number(dirname)
            result = super
            if result >= 30010000002020
              result = migration_lookup_at(dirname).select_map do |file|
                next if (version = File.basename(file).split("_").first.to_i) >= 30010000002020
                version
              end.max.to_i
            end
            result
          end
        end
      end
    end
  end
end

Rails::Generators::Migration.include Rails::Generators::Migration::WithRpcSchema
