module MixLog
  has_config do
    attr_writer   :partition_size
    attr_writer   :partitions_total_size
    attr_writer   :available_types
    attr_writer   :available_paths
    attr_writer   :available_rollups
    attr_writer   :filter_parameters
    attr_writer   :ided_paths
    attr_writer   :ided_errors
    attr_writer   :known_errors
    attr_accessor :force_read

    def partition_size
      @partition_size ||= :week
    end

    def partitions_total_size
      @partitions_total_size ||= 1.year
    end

    def available_types
      @available_types ||= {
        'LogLines::NginxAccess' => 10,
        'LogLines::NginxError'  => 20,
        'LogLines::Syslog'      => 30,
        'LogLines::Auth'        => 40,
        'LogLines::Fail2ban'    => 50,
        'LogLines::Postgresql'  => 60,
        'LogLines::Rails'       => 70,
        'LogLines::AptHistory'  => 80,
        'LogLines::Osquery'     => 90,
      }
    end

    def add_available_path(...)
      available_paths << log_path(...)
    end

    def available_paths
      @available_paths ||= [
        nginx_log_path(:access),
        nginx_log_path(:packs, :access),
        nginx_log_path(:public, :access),
        log_path(:nginx, :access),
        log_path(:nginx, :error),
        log_path(:apt, :history),
        log_path(:syslog),
        log_path(:auth),
        log_path(:fail2ban),
        postgres_log_path,
        osquery_log_path, # must be after 'apt/history.log'
        rails_log_path,
      ]
    end

    def available_rollups
      @available_rollups ||= {
        'LogRollups::NginxAccess' => 10,
      }
    end

    def filter_parameters
      @filter_parameters ||= Rails.application.config.filter_parameters.dup
    end

    def ided_paths
      @ided_paths ||= {}
    end

    def ided_errors
      @ided_errors ||= {
        %r{(SSL_do_handshake\(\) failed \(SSL: error:)(\w+)} => '\1*',
        %r{(ID: )(\w+)} => '\1*',
        %r{(details saved to: /tmp/passenger-error-)(\w+)} => '\1*',
        %r{(Cannot checkout session because a spawning error occurred\. The identifier of the error is )(\w+)} => '\1*',
        %r{(/tmp/passenger_native_support-)(\w+)} => '\1*',
      }
    end

    def known_errors
      @known_errors ||= {
        warn: [
          'SSL routines:tls_early_post_process_client_hello:version too low',
          'SSL routines:tls_early_post_process_client_hello:unsupported protocol',
        ],
        info: [
          '[passenger_native_support.so] trying to compile for the current user',
          'set PASSENGER_COMPILE_NATIVE_SUPPORT_BINARY',
          'Compilation successful. The logs are here:',
          '/tmp/passenger_native_support-',
          '[passenger_native_support.so] successfully loaded',
          'details saved to: /tmp/passenger-error-',
          /^ID: \w+$/,
        ]
      }.with_keyword_access
    end

    def postgres_log_path
      log_path("postgresql/postgresql-#{Setting[:postgres]}-main")
    end

    def osquery_log_path
      "#{Setting[:osquery_logger_path]}/osqueryd.results.log"
    end

    def rails_log_path
      "tmp/log/#{Rails.env}.log"
    end

    def nginx_log_path(*type, name)
      type = type.first
      name = "#{MixServer.config.deploy_dir}#{"_#{type.to_s.full_underscore}" if type}.#{name}"
      log_path(:nginx, name)
    end

    def log_path(*dirs, name)
      name = name.end_with?('log') ? name : "#{name}.log"
      path = [base_dir].concat(dirs) << name
      path.join('/')
    end

    def base_dir
      @base_dir ||=
        case Rails.env.to_sym
        when :test        then Gem.root('mix_log').join('test/fixtures/files/log').to_s
        when :development then 'tmp/log'
        else                   '/var/log'
        end
    end
  end
end
