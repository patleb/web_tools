# frozen_string_literal: true

module Kernel
  def thread(*args, priority: nil, **options)
    Thread.new(*args) do |*rest|
      Thread.current.abort_on_exception = true
      Thread.current.priority = priority if priority
      options.each do |name, value|
        Thread.current[name] = value
      end
      yield *rest
    end
  end

  def thread_shuttingdown?
    Thread.current.shuttingdown?
  end
end

class Thread
  SLEEP = 'sleep'

  def shuttingdown?
    group.shuttingdown?
  end

  def awake?
    !asleep?
  end

  def asleep?
    status == SLEEP
  end
end
