module MixLog
  class Extract < ActiveTask::Base
    class AccessDenied < ::StandardError; end

    def self.args
      {
        rotate:   ['--[no-]rotate',   'Rotate current logs before extracting'],
        parallel: ['--[no-]parallel', 'Run in parallel mode (default to true)']
      }
    end

    def self.defaults
      { parallel: !Rails.env.test? }
    end

    def extract
      sh 'sudo logrotate /etc/logrotate.conf --force' if options.rotate

      block = proc do |log|
        log.rotated_files.select{ |file| file.mtime.to_i > log.mtime.to_i }.each do |file|
          process log, file
        end
        log.finalize
      end

      options.parallel ? Parallel.each(logs, &block) : logs.each(&block)
    end

    private

    def process(log, file)
      lines = BulkProcessor.new(1000) do |batch|
        log.push_all(batch)
      end
      last_created_at, mtime = nil, file.mtime.utc

      if (path = file.to_s).end_with? '.gz'
        IO.popen("unpigz -c #{path}", 'rb') do |io|
          until io.eof?
            next if (line = io.gets).blank?
            last_created_at = process_line(log, line, lines, last_created_at, mtime)
          end
        end
      else
        File.foreach(path, chomp: true) do |line|
          next if line.blank?
          last_created_at = process_line(log, line, lines, last_created_at, mtime)
        end
      end
      lines.finalize

      log.update! mtime: mtime
    end

    def process_line(log, line, lines, last_created_at, mtime)
      lines << (line = log.parse(line, mtime: mtime)) # line.force_encoding('utf-8')
      line[:created_at] = last_created_at = normalize_timestamp(line[:created_at], last_created_at)
      lines.pop if line[:filtered]
      lines.process
      last_created_at
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
        MixLog.config.available_paths.map do |path|
          raise AccessDenied unless system("sudo chmod +r #{path}*")
          Log.find_or_create_by! server: Server.current, path: path
        end
      end
    end
  end
end
