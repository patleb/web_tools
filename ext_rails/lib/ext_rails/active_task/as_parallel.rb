# frozen_string_literal: true

module ActiveTask::AsParallel
  extend ActiveSupport::Concern

  class_methods do
    def args
      super.merge!(
        parallel: ['--[no-]parallel', 'Run in parallel mode (default to true)']
      )
    end

    def defaults
      super.merge!(
        parallel: !Rails.env.test?
      )
    end
  end

  protected

  def parallel(list, &block)
    options.parallel ? Parallel.each(list, &block) : list.each(&block)
  end
end
