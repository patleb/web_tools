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
        Parallel.each(logs, ar_base: LibMainRecord, &:rollups!.with(options.all))
      else
        logs.each(&:rollups!.with(options.all))
      end
    end

    private

    def logs
      @logs ||= begin
        log_lines = MixLog.config.available_rollups.keys.map{ |name| "LogLines::#{name.demodulize}" }
        Log.where(log_lines_type: log_lines)
      end
    end
  end
end
