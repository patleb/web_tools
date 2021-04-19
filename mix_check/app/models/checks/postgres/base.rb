module Checks
  module Postgres
    class Base < Checks::Base
      def self.db
        PgHero.primary_database
      end

      def self.ar_connection
        db.send(:connection_model).connection
      end

      def self.public?(row, *schema_keys)
        row.values_at(*schema_keys).all?{ |schema| schema == 'public' }
      end

      def self.exec_statement(name, one: false)
        one ? select_one(statements[name]) : select_all(statements[name])
      end

      def self.select_one(...)
        select_all(...).first
      end

      def self.select_all(sql, **options)
        db.send(:select_all, sql, **options)
      end

      def self.statements
        @@statements ||= begin
          pgmonitor_path = MixCheck::Engine.root.join('vendor/pgmonitor/exporter/postgres')
          pgmonitor = pgmonitor_path.glob('*.yml').each_with_object({}.with_keyword_access) do |yml, memo|
            yml = YAML.safe_load(yml.read)
              .transform_keys{ |key| key == 'ccp_locks' ? 'database_locks' : key.delete_prefix('ccp_') }
              .transform_values{ |hash| hash['query'].escape_newlines }
              .reject{ |_key, value| value.include? 'monitor.' }
            memo.merge! yml
          end
          pgextras_path = Gem.root('ruby-pg-extras').join('lib/ruby-pg-extras/queries')
          pgextras = pgextras_path.glob('*.sql').each_with_object({}.with_keyword_access) do |sql, memo|
            name = sql.basename('.sql').to_s
            next if (sql = sql.readlines.drop(1).join(' ').strip_sql).include? '%{'
            memo[name] = sql
          end
          pgmonitor.merge! pgextras
        end
      end
      private_class_method :statements
    end
  end
end
