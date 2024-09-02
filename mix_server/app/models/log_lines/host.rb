module LogLines
  class Host < LogLine
    json_attribute(
      version: :string,
      boot_time: :datetime,
      pids: :big_integer,
      usage: :float,
      steal: :float,
      load_avg: :float,
      disk_used: :big_integer,
      disk_reads: :big_integer,
      disk_writes: :big_integer,
      disk_inodes: :float,
      storage_used: :big_integer,
      storage_reads: :big_integer,
      storage_writes: :big_integer,
      storage_inodes: :float,
      ram: :big_integer,
      swap: :big_integer,
      bytes_in: :big_integer,
      bytes_out: :big_integer,
      postgres_pids: :integer,
      postgres_ram: :big_integer,
      ruby_pids: :integer,
      ruby_ram: :big_integer,
      sockets: :integer,
      issues: :json,
      warnings: :json,
    )

    scope :versioned, -> { where_not(version: nil) }
    scope :rebooted,  -> { where_not(boot_time: nil) }

    def self.versions
      versioned.order(created_at: :desc).pluck(:version)
    end

    def self.reboots
      rebooted.order(created_at: :desc).pluck(:boot_time)
    end

    def self.was_rebooted?(time)
      rebooted.where(boot_time: (time - Setting[:monit_interval])..(time + Setting[:monit_interval])).exists?
    end

    def self.was_deployed?(time)
      versioned.where(created_at: time..(time + Setting[:monit_interval])).exists?
    end

    def self.rollups
      %i(week day).each_with_object({}) do |period, result|
        group = group_by_period(period).calculate(LogRollups::Host::OPERATIONS)
        result[[period, :period]] = group.transform_values! do |row|
          row.map!.with_index do |value, i|
            next value.ceil(3) if rollups_keys[i] == :load_avg
            next value.ceil(2) if rollups_type(i) == :float
            value
          end
        end
      end
    end

    def self.push(log, row)
      level = :info
      level = :warn if row.warning?
      level = :error if row.issue?
      storage = if row.storage
        {
          **row.storage.slice(:used, :reads, :writes).transform_keys{ |k| "storage_#{k}" },
          storage_inodes: row.storage.inodes_usage
        }
      else
        {}
      end
      json_data = {
        version: row.version,
        **row.cpu.slice(:boot_time, :pids, :load_avg),
        usage: row.cpu.usage, steal: row.cpu.steal,
        **row.disk.slice(:used, :reads, :writes).transform_keys{ |k| "disk_#{k}" },
        disk_inodes: row.disk.inodes_usage,
        **storage,
        ram: row.memory.ram_used, swap: row.memory.swap_used,
        **row.network.slice(:bytes_in, :bytes_out),
        postgres_pids: row.postgres.pids, postgres_ram: row.postgres.ram,
        ruby_pids: row.ruby.pids, ruby_ram: row.ruby.ram,
        sockets: row.sockets.size,
        issues: row.issue_names,
        warnings: row.warning_names,
      }
      message = { text: row.ip, text_tiny: row.ip, level: level }
      super(log, message: message, json_data: json_data)
    end
  end
end
