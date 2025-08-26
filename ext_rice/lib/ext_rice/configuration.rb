module ExtRice
  has_config do
    attr_writer :log_levels
    attr_writer :log_level
    attr_writer :target
    attr_writer :yml_path
    attr_writer :app_path
    attr_writer :config_path
    attr_writer :vendor_path
    attr_writer :template
    attr_accessor :scope
    attr_accessor :executable
    alias_method  :executable?, :executable

    def log_levels
      @log_levels || %w(trace debug info warning error).map.with_index.to_h
    end

    def log_level
      @log_level || ENV['DEBUG'] ? 'debug' : (Rails.env.test? ? 'info' : 'warning')
    end

    def log_level_i
      log_levels[log_level]
    end

    def target
      Setting[:rice_target]
    end

    def yml_path
      @yml_path || Rails.root.join('config/rice.yml')
    end

    def app_path
      @app_path || Rails.root.join('app/rice')
    end

    def config_path
      @config_path || Rails.root.join('config/rice')
    end

    def vendor_path
      @vendor_path || Rails.root.join('vendor/rice')
    end

    def template
      @template ||= {}.to_hwia
    end
  end
end
