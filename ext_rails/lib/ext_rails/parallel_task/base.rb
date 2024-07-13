# frozen_string_literal: true

module ParallelTask
  class Base < ActiveTask::Base
    def self.args
      { parallel: ['--[no-]parallel', 'Run in parallel mode (default to true)'] }
    end

    def self.defaults
      { parallel: !Rails.env.test? }
    end

    protected

    def parallel(list, &block)
      options.parallel ? Parallel.each(list, &block) : list.each(&block)
    end
  end
end
