module MixLog
  class Rollup < ActiveTask::Base
    def self.args
      {
        all:      ['--[no-]all',      'Rebuild all rollups'],
        parallel: ['--[no-]parallel', 'Run in parallel mode (default to true)']
      }
    end

    def self.defaults
      { parallel: !Rails.env.test? }
    end

    def rollup
      if options.parallel
        Parallel.each(log_lines, &:rollups!.with(options.all))
      else
        log_lines.each(&:rollups!.with(options.all))
      end
    end

    private

    def log_lines
      @log_lines ||= MixLog.config.available_rollups.keys.map{ |name| "LogLines::#{name.demodulize}".to_const! }
    end
  end
end
