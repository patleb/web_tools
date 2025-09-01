module LogLines
  class Osquery < LogLine
    TINY_FILE_PATH = /(([A-Z]+_?)+,?)+/
    TINY_COMMAND_PATH = /((\d+\.)*\d+:\d+,?)+/

    json_attribute(
      name: :string,
      ram: :integer,
      paths: :json,
    )

    def self.names
      @names ||= Set.new(monitors).merge(threats)
    end

    def self.monitors
      @monitors ||= %w(
        osquery_info
        file_events
        socket_events
      )
    end

    def self.threats
      @threats ||= begin
        path = if Rails.env.local?
          MixServer::Engine.root.join('test/fixtures/files/osquery/ossec-rootkit.conf')
        else
          Pathname.new('/opt/osquery/share/osquery/packs/ossec-rootkit.conf')
        end
        rootkits = JSON.parse(path.read)['queries'].keys
        rootkits.concat(%w(
          backdoored_python_packages
          behavioral_reverse_shell
          ld_preload
        ))
      end
    end

    def self.conf
      @conf ||= begin
        path = if Rails.env.local?
          MixServer::Engine.root.join('test/fixtures/files/osquery/osquery.conf')
        else
          Pathname.new('/etc/osquery/osquery.conf')
        end
        JSON.parse(path.read).to_hwka
      end
    end



    def self.flags
      @flags ||= begin
        path = if Rails.env.local?
          MixServer::Engine.root.join('test/fixtures/files/osquery/osquery.flags')
        else
          Pathname.new('/etc/osquery/osquery.flags')
        end
        path.readlines(chomp: true).select_map do |line|
          next unless line.delete_prefix! '--'
          line.split('=', 2)
        end.to_h.to_hwka.transform_values(&:cast_self)
      end
    end

    def self.upgraded_binaries
      @upgraded_binaries ||= conf[:file_paths][:binaries].map(&:delete_suffix.with('%%'))
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
        message, paths = extract_paths(adds, name, tiny: TINY_FILE_PATH) do |row, memo|
          path = row['target_path']
          next if not_provisioned && path.end_with?("/#{Rails.stage}-job.service")
          next if was_upgraded && upgraded_binaries.any?{ |dir| path.start_with? dir }
          next if was_deployed && path.start_with?('/var/spool/cron/crontabs/')
          next if was_rebooted && path.start_with?('/etc/nginx/sites-available/')
          next if ssl_upgrade && path.start_with?('/etc/nginx/ssl/')
          next if MixServer::Logs.config.known_files.any? do |file|
            file.is_a?(Regexp) ? path.match?(file) : path == file
          end
          memo << [path.delete_suffix('/'), row['action']].join('/')
        end
      when 'socket_events'
        servers = Set.new(Cloud.server_ips)
        message, paths = extract_paths(adds, name, tiny: TINY_COMMAND_PATH) do |row, memo|
          next unless %w(connect bind).include? row['action']
          path = row.values_at('cmdline', 'path').find(&:present?) || ''
          local = row.values_at('local_address', 'local_port')
          remote = row.values_at('remote_address', 'remote_port')
          next if servers.include? remote.first
          next if MixServer::Logs.config.known_sockets.any? do |type, sockets|
            sockets.any? do |socket|
              case type
              when :path   then socket.is_a?(Regexp) ? path.match?(socket) : path.start_with?(socket)
              when :remote then socket.is_a?(Regexp) ? remote.first.match?(socket) : remote.first == socket
              end
            end
          end
          memo << [path, local.join(':'), remote.join(':')].join('/')
        end
      else
        message, paths = extract_paths(adds, name, tiny: TINY_COMMAND_PATH, level: :fatal) do |row, memo|
          path = row.values_at('cmdline', 'path', 'package_path', 'package_name').find(&:present?) || ''
          next if MixServer::Logs.config.nonthreats.any? do |nonthreat|
            nonthreat.is_a?(Regexp) ? path.match?(nonthreat) : path.start_with?(nonthreat)
          end
          memo << path
        end
      end
      return { filtered: true } unless message

      json_data = { name: name, ram: ram, paths: paths }

      { created_at: created_at, pid: pid, message: message, json_data: json_data }
    end

    def self.finalize(log)
      if Process.host.workers.select{ |worket| worket.name == 'osqueryd' }.empty?
        name = 'osquey_dead'
        push(log, message: { text: name, level: :error }, json_data: { name: name })
      end
    end

    def self.extract_paths(adds, name, tiny:, level: :error)
      paths = adds.each_with_object(SortedSet.new) do |row, memo|
        yield(row, memo)
      end.to_a

      return nil if paths.empty?

      text = [name, merge_paths(paths)].join(' ')
      text_tiny = text.gsub(/{?#{tiny}}?/, '*')
      [{ text: text, text_tiny: text_tiny, level: level }, paths]
    end
  end
end
