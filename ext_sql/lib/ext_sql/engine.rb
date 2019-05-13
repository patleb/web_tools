require "ext_sql/configuration"
require "ext_sql/active_support/core_ext/string"

module ExtSql
  class Engine < ::Rails::Engine
    if Rails.env.development? || Rails.env.test?
      require 'sql_query'

      initializer 'ext_sql.append_migrations' do |app|
        unless app.root.to_s.match(root.to_s)
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end
    end
  end
end
