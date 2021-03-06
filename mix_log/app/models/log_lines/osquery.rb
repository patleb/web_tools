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

    # TODO 'process_events'
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
        Pathname.new('/etc/osquery/osquery.flags.default').readlines(chomp: true).select_map do |line|
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

      time = Time.at(time).utc
      case name
      when 'osquery_info'
        pid, ram = diff['added'].first.values_at('pid', 'resident_size')
        level = ram > (flags[:watchdog_memory_limit] || 400).mb_to_bytes ? :error : :info
        message = { text: name, level: level }
      when 'file_events'
        has_upgraded = apt_history(log)&.has_upgraded? time
        paths = diff['added'].each_with_object(Set.new) do |row, memo|
          path = row['target_path']
          unless upgrade_paths.any?{ |dir| path.start_with? dir } && has_upgraded
            memo << path
          end
        end.to_a.sort
        return { filtered: true } if paths.empty?
        message = { text: [name, merge_paths(paths)].join(' '), level: :error }
      when 'socket_events'
        paths = diff['added'].each_with_object(Set.new) do |row, memo|
          # TODO add filters
          memo << row['path'] if %w(connect bind).include?(row['action'])
        end.to_a.sort
        return { filtered: true } if paths.empty?
        message = { text: [name, merge_paths(paths)].join(' '), level: :error }
      end
      json_data = { name: name, ram: ram, paths: paths }

      { created_at: time, pid: pid, message: message, json_data: json_data }
    end

    def self.finalize(log)
      unless where(log: log, created_at: (log.mtime - 1.day)..log.mtime).exists?
        name = 'osquey_dead'
        push(log, message: { text: name }, json_data: { name: name, level: :error })
      end
    end

    def self.merge_paths(paths)
      tokens = paths.each_with_object([]) do |path, memo|
        path.split('/').each_with_index do |token, i|
          (memo[i] ||= Set.new) << token
        end
      end
      tokens = tokens.map(&:to_a).map do |token|
        token.size > 1 ? "{#{token.join(',')}}" : token.first
      end
      tokens.join('/')
    end

    def self.apt_history(log)
      return unless Log.fs_types.include? 'LogLines::AptHistory'
      apt_history_path = MixLog.config.available_paths.find{ |path| path.end_with? 'apt/history.log'}
      apt_history_log = Log.find_or_create_by! server: log.server, path: apt_history_path
      LogLines::AptHistory.where(log: apt_history_log)
    end
  end
end
