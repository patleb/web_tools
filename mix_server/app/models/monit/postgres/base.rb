module Monit
  module Postgres
    class Base < Monit::Base
      delegate :db, to: :class

      def self.clear
        Monit::Postgres::Base.descendants.each(&:m_clear)
        reset
      end

      def self.db
        PgHero.primary_database
      end

      def self.db_name
        @@db_name ||= db.send(:connection_model).connection_db_config.configuration_hash[:database]
      end

      def self.db_user
        @@db_user ||= db.send(:connection_model).connection_db_config.configuration_hash[:username]
      end

      def self.db_host
        @@db_host ||= db.send(:connection_model).connection_db_config.configuration_hash[:host]
      end

      def self.db_indexes
        m_access(__method__){ db.indexes }
      end

      def self.ar_connection
        db.send(:connection_model).connection
      end

      def self.public?(row, schema_key = :schema)
        row[schema_key] == 'public'
      end

      def self.owner?(row)
        row[:user] == db_user
      end

      def self.exec_statement_one(name)
        exec_statement(name, one: true)
      end

      def self.exec_statement(name, one: false)
        one ? select_one(statements[name]) : select_all(statements[name])
      end

      def self.select_one(...)
        select_all(...).first
      end

      def self.select_all(...)
        db.send(:select_all, ...)
      end

      def self.statements
        @@statements ||= begin
          pgmonitor_path = MixServer::Engine.root.join('vendor/pgmonitor/postgres_exporter/common')
          pgmonitor = pgmonitor_path.glob('**/*.yml').each_with_object({}.to_hwka) do |yml, memo|
            yml = YAML.safe_load(yml.read)
              .transform_keys{ |key| key.delete_prefix('ccp_') }
              .transform_values{ |hash| hash['query'].escape_newlines }
            memo.merge! yml
          end
          pgextras_path = MixServer::Engine.root.join('vendor/ruby-pg-extras/queries')
          pgextras = pgextras_path.glob('*.sql').each_with_object({}.to_hwka) do |sql, memo|
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
