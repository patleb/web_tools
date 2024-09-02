# frozen_string_literal: true

module MixServer::Log
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
        log_lines = MixServer::Log.config.available_rollups.keys.map{ |name| "LogLines::#{name.demodulize}" }
        Log.where(log_lines_type: log_lines)
      end
    end
  end
end
