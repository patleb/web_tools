require "mix_sql/configuration"
require "mix_sql/active_support/core_ext/numeric"
require "mix_sql/active_support/core_ext/string"
require "mix_sql/sh"
require "mix_sql/sql"
require "sunzistrano/context"

module MixSql
  class Engine < ::Rails::Engine
    if Rails.env.development? || Rails.env.test?
      require 'sql_query'

      initializer 'mix_sql.append_migrations' do |app|
        append_migrations(app)
      end
    end
  end
end
