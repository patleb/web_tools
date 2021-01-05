module MixLog
  has_config do
    attr_writer :available_types
    attr_writer :available_paths

    def available_types
      @available_types ||= { # is it necessary... or only nginx and auth is useful
        'LogLines::NginxAccess' => 10,
        'LogLines::NginxError'  => 20,
        # TODO
        # auth: 0, # ssh access, or sudo last, wtmp
        # kern: 0, # reboot, crash, etc.
        # syslog: 0, # timestamp|host|program[pid]|text
        # fail2ban: 0,
        # monit: 0,
        # sysstat: 0,
        # goaccess: 0,
        # cron: 0, # add directly to ext_whenever instead
        # rails: 0, # add rescue to Rack instead... or add only FATAL level
        # rake: 0, # add directly to ext_rake instead
      }
    end

    def available_paths
      @available_paths ||= [
        nginx_log_path(:access),
        nginx_log_path(:error),
      ]
    end

    def filter_parameters
      @filter_parameters ||= Rails.application.config.filter_parameters + %w(
        CRS
        SRS
        TILED
        LAYERS
        STYLES
        TRANSPARENT
        REQUEST
        SERVICE
        VERSION
        FORMAT
        FORMAT_OPTIONS
        HEIGHT
      ) # GeoServer
    end

    def nginx_log_path(type, location = nil)
      log_path("nginx/#{deploy_dir}#{"_#{location.full_underscore}" if location}.#{type}")
    end

    def log_path(type)
      "#{base_dir}/#{type}.log"
    end

    def base_dir
      @base_dir ||= Rails.env.dev_or_test? ? 'tmp/log' : '/var/log'
    end

    def deploy_dir
      @deploy_dir ||= "#{Rails.app}_#{Rails.env}"
    end
  end
end
