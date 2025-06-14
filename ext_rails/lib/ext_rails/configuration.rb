module ExtRails
  has_config do
    attr_accessor :default_logger
    attr_accessor :i18n_debug
    attr_accessor :email_debug
    attr_accessor :sql_debug
    attr_accessor :params_debug
    attr_writer   :discardable
    attr_writer   :excluded_models
    attr_writer   :excluded_tables
    attr_writer   :temporary_tables
    attr_writer   :db_partitions
    attr_accessor :keep_install_migrations
    attr_writer   :theme, :themes
    attr_writer   :spinner
    attr_accessor :css_only_support
    attr_accessor :favicon_ico

    def discardable?
      return @discardable if defined? @discardable
      @discardable = ENV.has_key?('DISCARDABLE') ? ENV['DISCARDABLE'].to_b : true
    end

    def excluded_models
      @excluded_models ||= Set.new([
        'ApplicationRecord',
        'ApplicationMainRecord',
        'Current',
        'LibRecord',
        'LibMainRecord',
        'VirtualRecord::Relation'
      ])
    end

    def excluded_tables
      @excluded_tables ||= Set.new(['schema_migrations', 'ar_internal_metadata'])
    end

    def temporary_tables
      @temporary_tables ||= Set.new
    end

    def db_partitions
      @db_partitions ||= {}.to_hwka
    end

    def backup_excludes
      excluded_tables + temporary_tables
    end

    def themes
      @themes ||= { light: 'sun', dark: 'moon-stars-fill' }.to_hwka
    end

    def theme
      @theme ||= themes.keys.first.to_s
    end

    def spinner
      @spinner ||= :atom
    end
  end
end
