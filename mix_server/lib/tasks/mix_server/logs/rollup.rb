module MixServer::Logs
  class Rollup < ActiveTask::Base
    prepend ActiveTask::AsParallel

    def self.args
      super.merge!(
        all: ['--[no-]all', 'Rebuild all rollups'],
      )
    end

    def rollup
      parallel(logs, &:rollups!.with(options.all))
    end

    private

    def logs
      @logs ||= begin
        log_lines = MixServer::Logs.config.available_rollups.keys.map{ |name| "LogLines::#{name.demodulize}" }
        Log.where(log_lines_type: log_lines)
      end
    end
  end
end
