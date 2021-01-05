module MixLog
  class ExtractLogs < ActiveTask::Base
    class AccessDenied < ::StandardError; end

    def self.args
      {
        current:  ['--[no-]current',  'Extract current/in-use logs'],
        parallel: ['--[no-]parallel', 'Run in parallel mode (default to true)']
      }
    end

    def self.defaults
      {
        parallel: true
      }
    end

    def extract_logs
      block = proc do |log|
        if options.current
          next if (file = log.current_file).mtime.to_i > log.last_line_at.to_i
          process log, file
        else
          log.rotated_files.select{ |file| file.mtime.to_i > log.last_line_at.to_i }.each do |file|
            process log, file
          end
        end
        log.finalize
      end
      options.parallel ? Parallel.each(logs, &block) : logs.each(&block)
    end

    private

    def process(log, file)
      lines = BulkProcessor.new(1000) do |batch, last_line_i|
        log.push_all(batch)
        log.update! last_line_i: last_line_i
      end
      last_created_at, last_line_i, last_line_at = nil, 0, file.mtime

      if (path = file.to_s).end_with? '.gz'
        IO.popen("unpigz -c #{path}", 'rb') do |io|
          until io.eof?
            next if (line = io.gets).blank?
            last_created_at, last_line_i = process_line(log, line, lines, last_created_at, last_line_i)
          end
        end
      else
        File.foreach(path, chomp: true) do |line|
          next if line.blank?
          last_created_at, last_line_i = process_line(log, line, lines, last_created_at, last_line_i)
        end
      end
      lines.finalize(last_line_i)

      if options.current
        log.update! last_line_at: last_line_at
      else
        log.update! last_line_i: 0, last_line_at: last_line_at
      end
    end

    def process_line(log, line, lines, last_created_at, last_line_i)
      if last_line_i < log.last_line_i
        last_line_i += 1
      else
        lines << log.parse(line) # line.force_encoding('utf-8')
        lines.last[:created_at] = last_created_at = normalize_timestamp(lines.last[:created_at], last_created_at)
        last_line_i += 1
        lines.process(last_line_i)
      end
      [last_created_at, last_line_i]
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
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end
    end
  end
end
