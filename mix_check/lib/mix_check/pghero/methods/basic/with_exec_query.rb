module PgHero::Methods::Basic::WithExecQuery
  extend ActiveSupport::Concern

  included do
    alias_method :old_execute, :execute
    define_method :execute do |sql|
      connection.exec_query(add_source(sql)) # https://github.com/rails/rails/issues/22331
    end
  end
end

PgHero::Methods::Basic.include PgHero::Methods::Basic::WithExecQuery
