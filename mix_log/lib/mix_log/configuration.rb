module MixLog
  has_config do
    attr_writer :available_types
    attr_writer :available_paths
    attr_writer :filter_parameters
    attr_writer :ided_paths
    attr_writer :ided_errors
    attr_writer :known_errors

    def available_types
      @available_types ||= { # is it necessary... or only nginx and auth is useful
        'LogLines::NginxAccess' => 10,
        'LogLines::NginxError'  => 20,
        'LogLines::Syslog' => 30,
        # auth: 0, # ssh access, or sudo last, lastlog (binary) wtmp (binary)
        # kern: 0, # reboot, crash, etc.
        # syslog: 0, # timestamp|host|program[pid]|text
        # ufw
        # fail2ban: 0,
        #
        # monit: 0, --> keep monit, just improve the integration (it's not worth it to rewrite in Ruby)
        # sysstat: 0, --> needs sysstat installed in dev (actually, might be worth it to rewrite in Ruby and reuse like monit)
        #
        # postgres
        #
        # TODO cron: 0, # add directly to ext_whenever instead (or only in rake tasks?)
        # rack: 0, # add rescue to Rack and/or add only FATAL level log parsing (might be better if can't connect to postgres)
        #   --> action_dispatch/middleware/debug_exceptions.rb
        # rake: 0, # add directly to ext_rake instead (or only on start and finish/error?)
      }
    end

    def available_paths
      @available_paths ||= [
        nginx_log_path(:access),
        nginx_log_path(:error),
      ]
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
      @known_errors ||= HashWithIndifferentAccess.new(
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
      )
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
