require 'mix_setting'

module MixTask
  has_config do
    attr_writer   :available_names
    attr_writer   :durations_max_size
    attr_accessor :keep_install_migrations
    attr_writer   :db

    def available_names
      @available_names ||= {}
    end

    def durations_max_size
      @durations_max_size ||= 20
    end

    def rails_env
      ENV['RAILS_ENV'] || Rails.env
    end

    def rails_app
      ENV['RAILS_APP'] || Rails.app
    end

    def rails_root
      Pathname.new(ENV['RAILS_ROOT'] || Rails.root || '').expand_path
    end

    def db_adapter
      ActiveRecord::Base
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

    def db
      @db || ENV['DB']
    end

    def shared_dir
      case rails_env.to_s
      when 'development', 'test'
        rails_root
      else
        rails_root.join('..', '..', 'shared').expand_path
      end
    end
  end
end
