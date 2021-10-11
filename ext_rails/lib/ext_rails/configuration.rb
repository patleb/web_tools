module ExtRails
  has_config do
    attr_accessor :i18n_debug
    attr_writer :sql_debug
    attr_writer :params_debug
    attr_writer :skip_discard
    attr_writer :excluded_models
    attr_writer :excluded_tables
    attr_writer :temporary_tables
    attr_writer :db_partitions

    def sql_debug?
      return @sql_debug if defined? @sql_debug
      @sql_debug = Rails.env.dev_or_test? if defined? Rails
    end

    def params_debug?
      return @params_debug if defined? @params_debug
      @params_debug = Rails.env.dev_or_test?
    end

    def skip_discard?
      return @skip_discard if defined? @skip_discard
      @skip_discard = ENV['SKIP_DISCARD'].to_b
    end

    def excluded_models
      @excluded_models ||= Setting[:timescaledb_enabled] ? Set.new : Set.new(['Timescaledb::Chunk', 'Timescaledb::Table'])
    end

    def excluded_tables
      @excluded_tables ||= Set.new([ActiveRecord::SchemaMigration.table_name, ActiveRecord::InternalMetadata.table_name])
    end

    def temporary_tables
      @temporary_tables ||= Set.new
    end

    def db_partitions
      @db_partitions ||= {}.with_keyword_access
    end

    def backup_excludes
      excluded_tables + temporary_tables
    end
  end
end
