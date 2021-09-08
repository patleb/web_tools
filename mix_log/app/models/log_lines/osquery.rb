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
        rootkits = Pathname.new('/usr/share/osquery/packs/ossec-rootkit.conf')
        rootkits = JSON.parse(rootkits.read)['queries'].keys
        rootkits.concat(%w(
          backdoored_python_packages
          behavioral_reverse_shell
          ld_preload
        ))
      end
    end

    def self.conf
      @@conf ||= JSON.parse(Pathname.new('/etc/osquery/osquery.conf').read).with_keyword_access
    end

    def self.flags
      @@flags ||= begin
        Pathname.new('/etc/osquery/osquery.flags').readlines(chomp: true).select_map do |line|
          next unless line.delete_prefix! '--'
          line.split('=', 2)
        end.to_h.with_keyword_access.transform_values(&:cast)
      end
    end

    def self.upgrade_paths
      @@upgrade_paths ||= conf[:file_paths][:binaries].map(&:delete_suffix.with('%%'))
    end

    def self.parse(log, line, **)
      name, time, diff = JSON.parse(line).values_at('name', 'unixTime', 'diffResults')
      return { filtered: true } unless names.include? name

      created_at = Time.at(time).utc
      case name
      when 'osquery_info'
        pid, ram = diff['added'].first.values_at('pid', 'resident_size')
        level = ram > flags[:watchdog_memory_limit].mb_to_bytes ? :error : :info
        message = { text: name, level: level }
      when 'file_events'
        has_upgraded = apt_history(log)&.has_upgraded? created_at
        ssl_upgrade = task(log)&.ssl_upgrade? created_at
        message, paths = extract_paths(diff, name, tiny: /(([A-Z]+_?)+,?)+/) do |row, memo|
          path = row['target_path']
          next if upgrade_paths.any?{ |dir| path.start_with? dir } && has_upgraded
          next if path.start_with?('/etc/nginx/ssl/') && ssl_upgrade
          next if MixLog.config.known_files.any? do |f|
            f.is_a?(Regexp) ? path.match?(f) : path == f
          end
          memo << [path, row['action']].join('/')
        end
      when 'socket_events'
        # Setting[:server_cluster_master_ip]
        # ips = Set.new([Process.host.private_ip]).merge(Cloud.server_cluster_ips || [])
        message, paths = extract_paths(diff, name, tiny: /((\d+\.)*\d+:\d+,?)+/) do |row, memo|
          next unless %w(connect bind).include? row['action']
          path = row['cmdline']
          local = row.values_at('local_address', 'local_port')
          remote = row.values_at('remote_address', 'remote_port')
          next if MixLog.config.known_sockets.any? do |type, sockets|
            sockets.any? do |s|
              case type
              when :path
                s.is_a?(Regexp) ? path.match?(s) : path == s
              end
            end
          end
          memo << [path, local.join(':'), remote.join(':')].join('/')
        end
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

    def self.extract_paths(diff, name, tiny: nil)
      paths = diff['added'].each_with_object(Set.new) do |row, memo|
        yield(row, memo)
      end.to_a.sort

      return nil if paths.empty?

      text = [name, merge_paths(paths)].join(' ')
      text_tiny = text.gsub(/{?#{tiny}}?/, '*') if tiny
      [{ text: text, text_tiny: text_tiny, level: :error }, paths]
    end
  end
end
