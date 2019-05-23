require "ext_sql/configuration"
require "ext_sql/active_support/core_ext/string"

module ExtSql
  class Engine < ::Rails::Engine
    if Rails.env.development? || Rails.env.test?
      require 'sql_query'

      initializer 'ext_sql.append_migrations' do |app|
        append_migrations(app)
      end
    end
  end
end
