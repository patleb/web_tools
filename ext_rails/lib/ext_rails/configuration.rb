# frozen_string_literal: true

module ExtRails
  has_config do
    attr_accessor :default_logger
    attr_writer   :rescue_500
    attr_accessor :i18n_debug
    attr_accessor :email_debug
    attr_writer   :sql_debug
    attr_writer   :params_debug
    attr_writer   :skip_discard
    attr_writer   :excluded_models
    attr_writer   :excluded_tables
    attr_writer   :temporary_tables
    attr_writer   :db_partitions
    attr_accessor :keep_install_migrations
    attr_writer   :theme
    attr_accessor :css_only_support
    alias_method  :css_only_support?, :css_only_support
    attr_accessor :favicon_ico
    alias_method  :favicon_ico?, :favicon_ico

    def rescue_500
      return @rescue_500 if defined? @rescue_500
      @rescue_500 = !Rails.env.development?
    end

    def sql_debug?
      return @sql_debug if defined? @sql_debug
      @sql_debug = Rails.env.local?
    end

    def params_debug?
      return @params_debug if defined? @params_debug
      @params_debug = Rails.env.local?
    end

    def skip_discard?
      return @skip_discard if defined? @skip_discard
      @skip_discard = ENV['SKIP_DISCARD'].to_b
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
      @db_partitions ||= {}.with_indifferent_access
    end

    def backup_excludes
      excluded_tables + temporary_tables
    end

    def theme
      @theme ||= 'light'
    end
  end
end
