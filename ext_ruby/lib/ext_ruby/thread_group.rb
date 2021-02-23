### References
# https://ruby-concurrency.github.io/concurrent-ruby/Concurrent/ThreadPoolExecutor.html
class ThreadGroup
  class MaxThreadsInvalid < ::ArgumentError; end
  class MaxThreadsReached < ::StandardError; end
  class TimeoutInvalid < ::ArgumentError; end
  class TimeoutKillPeriodInvalid < ::ArgumentError; end
  class TimeoutError < ::StandardError; end

  TIMEOUT = 'timeout'.freeze

  module WithThreadPoolExecutor
    attr_reader :max_length, :largest_length

    alias_method :max_queue, :max_length

    def initialize(max_threads = Float::INFINITY)
      raise MaxThreadsInvalid if !max_threads.is_a?(Numeric) || (max_threads < 1)

      @max_length = max_threads
      @largest_length = 0
      @timeout_mutex = Mutex.new

      super()
    end

    def length(with = :alive)
      if with == :awake
        list.count(&:awake?)
      else
        list.size
      end
    end
    alias_method :queue_length, :length

    def remaining_capacity(with = :alive)
      if with == :asleep
        max_length - length(:awake)
      else
        max_length - length
      end
    end

    def running?
      list.any?
    end

    def shutdown
      @shutdown = true
    end

    def shutdown!
      shutdown
      list.select(&:asleep?).each(&:kill)
    end

    def shutdown?
      list.empty?
    end

    def shuttingdown?
      @shutdown.to_b && running?
    end

    def timeout(seconds, *args, kill_on_expired: false, **options)
      return if ENV['DEBUGGER_HOST']
      raise TimeoutInvalid if !seconds.is_a?(Numeric) || (seconds <= 0)
      raise TimeoutKillPeriodInvalid if kill_on_expired.is_a?(Numeric) && kill_on_expired <= 0

      future = Time.now.to_f + seconds
      @timeout_mutex.synchronize{ @max_length += 1 }

      add(*args, name: TIMEOUT, _timeout: true, **options) do |*rest|
        until (expired = future < Time.now.to_f) || thread_shuttingdown?
          sleep 0.01
        end

        yield expired, *rest if block_given?

        if expired
          case (grace_period = kill_on_expired)
          when true    then kill
          when Numeric then kill(grace_period)
          end
          raise TimeoutError
        end
      ensure
        @timeout_mutex.synchronize{ @max_length -= 1 }
      end
    end

    def post_all(*args, &block)
      @max_length.times{ add(*args, &block) }
      self
    end

    def add(*args, &block)
      raise MaxThreadsReached if remaining_capacity == 0

      if args.first.is_a? Thread
        super args.first
      else
        super thread(*args, &block)
      end

      @largest_length = length if length > largest_length

      self
    end
    alias_method :post, :add

    def join(*timeout)
      list(without_self: true).each(&:join.with(*timeout))
    end
    alias_method :wait_for_termination, :join

    def kill(*timeout)
      if timeout.empty?
        @timeout_mutex.synchronize do
          list.each do |thread|
            @max_length -= 1 if thread[:_timeout]
            thread.kill
          end
        end
      else
        shutdown!
        join(*timeout)
        yield list.select(&:awake?) if block_given?
        kill
      end
    end

    def list(without_self: false)
      threads = super()
      current = threads.delete(Thread.current)
      threads << current if !without_self && current
      threads
    end
  end
  prepend WithThreadPoolExecutor
end
