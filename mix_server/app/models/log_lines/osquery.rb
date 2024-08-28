module LogLines
  class Osquery < LogLine
    json_attribute(
      name: :string,
      ram: :integer,
      paths: :json,
    )

    def self.names
      @@names ||= Set.new(monitors).merge(threats)
    end

    def self.monitors
      @@monitors ||= %w(
        osquery_info
        file_events
        socket_events
      )
    end

    def self.threats
      @@threats ||= begin
        rootkits = Pathname.new('/opt/osquery/share/osquery/packs/ossec-rootkit.conf')
        rootkits = JSON.parse(rootkits.read)['queries'].keys
        rootkits.concat(%w(
          backdoored_python_packages
          behavioral_reverse_shell
          ld_preload
        ))
      end
    end

    def self.conf
      @@conf ||= JSON.parse(Pathname.new('/etc/osquery/osquery.conf').read).with_indifferent_access
    end

    def self.flags
      @@flags ||= begin
        Pathname.new('/etc/osquery/osquery.flags').readlines(chomp: true).select_map do |line|
          next unless line.delete_prefix! '--'
          line.split('=', 2)
        end.to_h.with_indifferent_access.transform_values(&:cast_self)
      end
    end

    def self.upgraded_binaries
      @@upgraded_binaries ||= conf[:file_paths][:binaries].map(&:delete_suffix.with('%%'))
    end

    def self.parse(log, line, **)
      name, time, diff = JSON.parse(line.tr("\0", '')).values_at('name', 'unixTime', 'diffResults')
      return { filtered: true } unless names.include? name
      return { filtered: true } if (adds = diff['added']).empty?

      created_at = Time.at(time).utc
      case name
      when 'osquery_info'
        pid, ram = adds.first.values_at('pid', 'resident_size')
        level = ram > (flags[:watchdog_memory_limit] + 100).mb_to_bytes ? :error : :info
        message = { text: name, level: level }
      when 'file_events'
        not_provisioned = !Server.provisioned?(created_at)
        was_upgraded = apt_history(log)&.was_upgraded? created_at
        was_deployed = host(log)&.was_deployed? created_at
        was_rebooted = host(log)&.was_rebooted? created_at
        ssl_upgrade = task(log)&.ssl_upgrade? created_at
        message, paths = extract_paths(adds, name, tiny: /(([A-Z]+_?)+,?)+/) do |row, memo|
          path = row['target_path']
          next if not_provisioned && path.end_with?("/#{Rails.app}_#{Rails.env}-job-default.service")
          next if was_upgraded && upgraded_binaries.any?{ |dir| path.start_with? dir }
          next if was_deployed && path.start_with?('/var/spool/cron/crontabs/')
          next if was_rebooted && path.start_with?('/etc/nginx/sites-available/')
          next if ssl_upgrade && path.start_with?('/etc/nginx/ssl/')
          next if MixServer::Log.config.known_files.any? do |f|
            f.is_a?(Regexp) ? path.match?(f) : path == f
          end
          memo << [path.delete_suffix('/'), row['action']].join('/')
        end
      when 'socket_events'
        servers = Set.new(Cloud.servers)
        message, paths = extract_paths(adds, name, tiny: /((\d+\.)*\d+:\d+,?)+/) do |row, memo|
          next unless %w(connect bind).include? row['action']
          path = row.values_at('cmdline', 'path').reject(&:blank?).first || ''
          local = row.values_at('local_address', 'local_port')
          remote = row.values_at('remote_address', 'remote_port')
          next if servers.include? remote.first
          next if MixServer::Log.config.known_sockets.any? do |type, sockets|
            sockets.any? do |s|
              case type
              when :path   then s.is_a?(Regexp) ? path.match?(s) : path.start_with?(s)
              when :remote then s.is_a?(Regexp) ? remote.first.match?(s) : remote.first == s
              end
            end
          end
          memo << [path, local.join(':'), remote.join(':')].join('/')
        end
      else
        message = { text: "threat #{name}", level: :fatal }
      end
      return { filtered: true } unless message

      json_data = { name: name, ram: ram, paths: paths }

      { created_at: created_at, pid: pid, message: message, json_data: json_data }
    end

    def self.finalize(log)
      if Process.host.workers.select{ |w| w.name == 'osqueryd' }.empty?
        name = 'osquey_dead'
        push(log, message: { text: name, level: :error }, json_data: { name: name })
      end
    end

    def self.extract_paths(adds, name, tiny: nil)
      paths = adds.each_with_object(Set.new) do |row, memo|
        yield(row, memo)
      end.to_a.sort

      return nil if paths.empty?

      text = [name, merge_paths(paths)].join(' ')
      text_tiny = text.gsub(/{?#{tiny}}?/, '*') if tiny
      [{ text: text, text_tiny: text_tiny, level: :error }, paths]
    end
  end
end
