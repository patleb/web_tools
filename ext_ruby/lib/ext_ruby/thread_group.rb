# frozen_string_literal: true

class ThreadGroup
  class MaxThreadsInvalid < ::ArgumentError; end
  class MaxThreadsReached < ::StandardError; end
  class TimeoutInvalid < ::ArgumentError; end

  TIMEOUT = 'timeout'

  module WithThreadPool
    # ThreadGroup::Default doesn't go through #initialize so ivars aren't initialized
    def initialize(max_threads: Float::INFINITY)
      raise MaxThreadsInvalid if !max_threads.is_a?(Numeric) || (max_threads < 1)
      @max_threads = max_threads
      super()
    end

    def max_threads
      @max_threads ||= Float::INFINITY
    end

    def max_size
      @max_size ||= 0
    end

    def size
      list.size
    end

    def remaining_threads
      max_threads - size
    end

    def running?
      list.any?
    end

    def shutdown!
      @shutdown = true
    end

    def shutdown?
      list.empty?
    end

    def shuttingdown?
      !!@shutdown
    end

    def [](name)
      list.find{ |thread| thread[:name] == name }
    end

    def timeout(seconds, *, **)
      return if ENV['DEBUGGER_HOST']
      raise TimeoutInvalid if !seconds.is_a?(Numeric) || (seconds <= 0)
      future = Time.current.to_f + seconds
      timeout_mutex.synchronize{ @max_threads += 1 }
      post(*, **, name: TIMEOUT, _timeout: true) do |*args|
        until (expired = future < Time.current.to_f) || thread_shuttingdown?
          sleep 0.01
        end
        yield expired, *args
        kill_all if expired
      ensure
        timeout_mutex.synchronize{ @max_threads -= 1 } if future
      end
    end

    def post_all(*, **, &)
      raise MaxThreadsInvalid if max_threads.infinite?
      max_threads.times{ |i| post(*, i, **, i: i, &) }
      self
    end

    def post(...)
      raise MaxThreadsReached if remaining_threads == 0
      group_thread = thread(...)
      add group_thread
      @max_size = size if size > max_size
      group_thread
    end

    def join_all(*)
      list.each(&:join.with(*))
    end

    def kill_all(*timeout)
      if timeout.empty?
        timeout_mutex.synchronize do
          list.each do |thread|
            thread.kill
            @max_threads -= 1 if thread[:_timeout]
          end
        end
      else
        join_all(*timeout)
        kill_all
      end
    end

    private

    def timeout_mutex
      @timeout_mutex ||= Mutex.new
    end
  end
  prepend WithThreadPool
end
