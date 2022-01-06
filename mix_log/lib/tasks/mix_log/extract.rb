module MixLog
  class Extract < ParallelTask::Base
    class AccessDenied < ::StandardError; end

    def self.args
      super.merge!(
        rotate: ['--[no-]rotate', 'Rotate current logs before extracting'],
      )
    end

    def extract
      sh 'sudo logrotate /etc/logrotate.conf --force' if options.rotate # cat /var/lib/logrotate/status

      parallel(logs) do |log|
        log.rotated_files.select{ |file| file.mtime.to_i > log.mtime.to_i }.each do |file|
          puts "Processing: #{file}" if MixLog.config.log_debug
          process log, file
        end
        log.finalize
      end
    end

    private

    def process(log, file)
      lines = BulkProcessor.new(1_000) do |batch, line_i|
        log.push_all(batch)
        log.update! line_i: line_i
      end
      last_created_at, line_i, mtime = nil, 0, file.mtime.utc

      read_file(file) do |line|
        last_created_at, line_i = process_line(log, line, lines, last_created_at, line_i, mtime)
      end
      lines.finalize(line_i)

      log.update! line_i: 0, mtime: mtime
    end

    def process_line(log, line, lines, last_created_at, line_i, mtime)
      if line_i < log.line_i
        line_i += 1
      else
        previous = lines.last
        lines << (line = log.parse(line, mtime: mtime, previous: previous)) # line.force_encoding('utf-8')
        line[:created_at] = last_created_at = normalize_timestamp(line[:created_at], last_created_at)
        line_i += 1
        lines.delete_at(-2) if line.delete(:anchored)
        lines.pop if line[:filtered]
        lines.process(line_i)
      end
      [last_created_at, line_i]
    end

    def normalize_timestamp(created_at, last_created_at)
      if created_at && last_created_at
        if last_created_at > created_at
          last_created_at + 1.0e-6
        elsif last_created_at == created_at
          created_at + 2.0e-6 # needed, otherwise it rounds at .0
        else
          created_at
        end
      else
        created_at || last_created_at
      end
    end

    def logs
      @logs ||= begin
        MixLog.config.available_paths.sort_by{ |path| path.split('/').last(2) }.select_map do |path|
          if MixLog.config.force_read
            raise AccessDenied unless system("sudo chmod +r #{path}.*")
          end
          if %W(#{path} #{path}.0 #{path}.1 #{path}.1.gz).any?{ |file| File.exist? file }
            Log.find_or_create_by! server: Server.current, path: path
          end
        end
      end
    end
  end
end
