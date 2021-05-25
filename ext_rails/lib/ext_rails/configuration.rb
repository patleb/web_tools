module ExtRails
  has_config do
    attr_accessor :i18n_debug
    attr_writer :sql_debug
    attr_writer :params_debug
    attr_writer :skip_discard
    attr_writer :excluded_models
    attr_writer :backup_excludes
    attr_writer :backup_dir

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
      @excluded_models ||= Set.new
    end

    def backup_excludes
      @backup_excludes ||= Set.new
    end

    def backup_dir
      @backup_dir ||= Rails.root.join('db')
    end

    def db_url
      db = db_config
      "postgresql://#{db[:username]}:#{db[:password]}@#{db[:host]}:5432/#{db[:database]}"
    end

    def db_config
      {
        host: Setting[:db_host],
        database: Setting[:db_database],
        username: Setting[:db_username],
        password: Setting[:db_password],
      }
    end
  end
end
