module MixServer
  module Logs
    DB_TYPE = 1000

    has_config do
      attr_writer   :show_path
      attr_writer   :partitions_total_size
      attr_writer   :available_types
      attr_writer   :available_paths
      attr_writer   :available_rollups
      attr_writer   :filter_parameters
      attr_writer   :filter_endings
      attr_writer   :filter_ips
      attr_writer   :ided_paths
      attr_writer   :ided_errors
      attr_writer   :known_errors
      attr_writer   :known_sockets
      attr_writer   :nonthreats
      attr_accessor :force_read

      def show_path?
        return @show_path if defined? @show_path
        @show_path = Rails.env.staging?
      end

      def partitions_total_size
        @partitions_total_size ||= 1.year
      end

      def available_types
        @available_types ||= {
          'LogLines::Syslog'      => 0,
          'LogLines::NginxAccess' => 10,
          'LogLines::NginxError'  => 20,
          'LogLines::Auth'        => 30,
          'LogLines::Postgresql'  => 40,
          'LogLines::App'         => 50,
          'LogLines::AptHistory'  => 60,
          'LogLines::Osquery'     => 70,
          'LogLines::Rescue'      => DB_TYPE,
          'LogLines::Email'       => DB_TYPE + 10,
          'LogLines::Worker'      => DB_TYPE + 20,
          'LogLines::Clamav'      => DB_TYPE + 30,
          'LogLines::Database'    => DB_TYPE + 40,
          'LogLines::Host'        => DB_TYPE + 50,
        }
      end

      def add_available_path(...)
        available_paths << log_path(...)
      end

      def available_paths
        @available_paths ||= (Rails.env.test? ? [
          log_path(:syslog)
        ] : []).concat([
          passenger_log_path(:access),
          passenger_log_path(:packs, :access),
          passenger_log_path(:public, :access),
          log_path(:nginx, :error),
          log_path(:auth),
          postgres_log_path,
          rails_log_path,
          log_path(:apt, :history),
          osquery_log_path,
        ])
      end

      def available_rollups
        @available_rollups ||= {
          'LogRollups::NginxAccess' => available_types['LogLines::NginxAccess'],
          'LogRollups::Database'    => available_types['LogLines::Database'],
          'LogRollups::Host'        => available_types['LogLines::Host'],
        }
      end

      def filter_parameters
        @filter_parameters ||= Rails.application.config.filter_parameters.dup
      end

      def filter_endings
        @filter_endings ||= ['/wp-admin', '/allowurl.txt', '.php']
      end

      def filter_ips
        @filter_ips ||= Set.new
      end

      def filter_subnets
        @filter_subnets ||= filter_ips.to_a.concat(Setting[:denied_ips]).map{ |subnet| IPAddr.new(subnet) }
      end

      def ided_paths
        @ided_paths ||= {
          %r{^(/packs/.+)(-[a-f0-9]+)((?:\.chunk)?\.[a-z0-9]{1,5})(\.map)?$} => '\1-*\3\4',
          %r{^/storage/.+} => '/storage/*',
        }
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
            'SSL routines:ssl3_read_bytes:invalid alert',
            'SSL routines:tls_early_post_process_client_hello:version too low',
            'SSL routines:tls_early_post_process_client_hello:unsupported protocol',
            'SSL routines:tls_parse_ctos_key_share:bad key share',
            'SSL routines:tls_choose_sigalg:internal error',
            'access forbidden by rule',
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
        }
      end

      # https://github.com/osquery/osquery/issues/4750
      def known_files
        @known_files ||= [
          "/home/#{Setting[:deployer_name]}/.ssh/known_hosts",
          '/root/.ssh/known_hosts',
          '/etc/.pwd.lock',
          '/etc/ssh/sshd_config~',
          %r{^/etc/lvm/cache(/\.cache(\.tmp)?)?$},
          %r{^/etc/ld\.so\.cache~?$},
          %r{^/etc/fwupd/},
          %r{^/etc/pki/fwupd(-metadata)?/},
          '/etc/libblockdev',
          %r{/etc/mailcap(\.new)?$},
          '/etc/udisks2',
          '/etc/update-motd.d/85-fwupd',
          '/etc/apt/apt.conf.d/01autoremove-kernels',
          %r{^/(etc|usr/s?bin)/[-.\w/]+\.dpkg-(old|new|tmp)$},
          %r{^/etc/([-.\w]+/)*sed\w{1,8}$},
          %r{^/etc/ssh/\.\w+$},
          %r{^/etc/systemd/system/\.[-.\w]+$},
          %r{^/etc/systemd/system/(multi-user|sockets)\.target\.wants/snap[-.][-.\w~]+$},
          %r{^/etc/systemd/system/snap[-.][-.\w~]+$},
          %r{^/etc/logrotate\.d/\.\w+$},
          %r{^/etc/nginx/\.\w+$},
          %r{^/etc/nginx/sites-available/\.\w+$},
          %r{^/etc/osquery/\.osquery\.\w+$},
          %r{^/etc/(localtime|timezone)$},
          %r{^/etc/udev/rules\.d/70-snap\.snapd\.rules(\.\w+~)?$},
          %r{^/var/spool/cron/crontabs(/tmp\.\w{1,8}|/#{Setting[:deployer_name]})?$},
          %r{^/usr/bin/(dbxtool|dfu-tool|fwupdagent|fwupdate|fwupdmgr|fwupdtool|fwupdtpmevlog|udisksctl)$},
          '/usr/sbin/umount.udisks2',
        ]
      end

      def known_sockets
        @known_sockets ||= {
          path: [
            'node /usr/share/yarn/bin/yarn.js install',
            %r{^/home/#{Setting[:deployer_name]}/\.rbenv/versions/[.\d]+/bin/ruby /home/#{Setting[:deployer_name]}/\.rbenv/versions/[.\d]+/bin/bundle install},
            %r{^/home/#{Setting[:deployer_name]}/\.rbenv/versions/[.\d]+/bin/ruby /home/#{Setting[:deployer_name]}/\.rbenv/versions/[.\d]+/bin/bundle .+ --deployment .+/\.local_repo/},
            "Passenger RubyApp: /home/#{Setting[:deployer_name]}/",
            'ruby bin/rake cron:every_day', # geolite fetch or email on errors
            'ruby bin/rake runner[Monit.capture]', # email on errors
            'ruby bin/rake job:watch -- --queue=', # email on errors
            %r{^/usr/sbin/ntpd -p /var/run/ntpd.pid -g -u \d+:\d+},
            '/usr/bin/freshclam -d --foreground=true',
            '/usr/lib/snapd/snapd',
            '/usr/bin/python3 /usr/lib/ubuntu-release-upgrader/check-new-release -q',
            '/usr/lib/apt/methods/http', # apt update
          ],
          remote: %w(
            127.0.0.1
            0000:0000:0000:0000:0000:ffff:7f00:0001
            127.0.0.53
            0000:0000:0000:0000:0000:ffff:7f00:0035
            0
            0.0.0.0
            0000:0000:0000:0000:0000:0000:0000:0000
          ).concat(
            (%w(169.254 172.17 172.18 10 192.168) + (88..95).map{ |i| "91.189.#{i}" }).map{ |ip| /^#{ip}\./ } # private networks + ubuntu ip ranges
          ).concat(
            Array.wrap(Setting[:ftp_host])
          ),
        }
      end

      def nonthreats
        @nonthreats ||= [
          'ruby bin/rake runner[Monit.capture]',
        ]
      end

      def postgres_log_path
        log_path("postgresql/postgresql-#{Setting[:postgres]}-main")
      end

      def osquery_log_path
        "#{Setting[:osquery_logger_path]}/osqueryd.results.log"
      end

      def rails_log_path
        "log/#{Rails.env}.log"
      end

      def passenger_log_path(*type, name)
        type = type.first
        name = "#{Rails.stage}#{"-#{type.to_s.full_underscore}" if type}.#{name}"
        log_path(:nginx, name)
      end

      def log_path(*dirs, name)
        name = name.end_with?('log') ? name : "#{name}.log"
        path = [base_dir].concat(dirs) << name
        path.join('/')
      end

      def base_dir
        @base_dir ||= case Rails.env.to_sym
          when :test        then Gem.root('mix_server').join('test/fixtures/files/log').to_s
          when :development then 'tmp/log'
          else                   '/var/log'
          end
      end
    end
  end
end
