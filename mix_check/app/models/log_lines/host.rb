module LogLines
  class Host < LogLine
    json_attribute(
      ip: :string,
      boot_time: :datetime,
      pids: :integer,
      work: :integer,
      idle: :integer,
      steal: :integer,
      load_avg: :float,
      disk_size: :integer,
      disk_reads: :integer,
      disk_writes: :integer,
      disk_inodes: :float,
      storage_size: :integer,
      storage_read: :integer,
      storage_writes: :integer,
      storage_inodes: :float,
      memory_size: :integer,
      swap_size: :integer,
      bytes_in: :integer,
      bytes_out: :integer,
      postgres_pids: :integer,
      postgres_size: :integer,
      ruby_pids: :integer,
      ruby_size: :integer,
      sockets: :integer,
      issues: :json,
      warnings: :json,
    )

    def self.push(log, row)
      level = :info
      level = :warn if row.warning?
      level = :error if row.issue?
      storage = if row.storage
        {
          **row.storage.slice(:size, :reads, :writes).transform_keys{ |k| "storage_#{k}" },
          storage_inodes: row.storage.inodes_usage
        }
      else
        {}
      end
      json_data = {
        **row.cpu.slice(:boot_time, :pids, :work, :idle, :steal, :load_avg),
        **row.disk.slice(:size, :reads, :writes).transform_keys{ |k| "disk_#{k}" },
        disk_inodes: row.disk.inodes_usage,
        **storage,
        memory_size: row.memory.size, swap_size: row.memory.swap_size,
        **row.network.slice(:bytes_in, :bytes_out),
        postgres_pids: row.postgres.pids, postgres_size: row.postgres.memory_size,
        ruby_pids: row.ruby.pids, ruby_size: row.ruby.memory_size,
        sockets: row.sockets.size,
        issues: row.issue_names(false),
        warnings: row.warning_names(false),
      }
      message = { text: ['host', (json_data[:issues] + json_data[:warnings]).uniq].join!(' '), level: level }
      super(log, message: message, json_data: json_data)
    end
  end
end
