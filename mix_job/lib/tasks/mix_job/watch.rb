# TODO helpers for tmp/jobs/actions with Cron jobs and Incron watchers
# https://layerci.com/blog/postgres-is-the-answer/
module MixJob
  class Watch < ActiveTask::Base
    # TERM --> by System Monitor
    # HUP  --> by Closing Terminal
    # INT  --> by Systemd / Ctrl-C / IDE
    SHUTDOWN_SIGNALS = IceNine.deep_freeze(ENV['DEBUGGER_HOST'] ? %w(TERM HUP): %w(TERM HUP INT))
    SHUTDOWN_SIGNAL  = 'TERM'.freeze # used in tests
    INSPECT_SIGNAL   = 'USR1'.freeze
    EXECUTE_SIGNAL   = 'USR2'.freeze
    SIGNALS = IceNine.deep_freeze(
      SHUTDOWN_SIGNALS.map{ |signal| [signal, :shutdown] }.to_h.merge!(
        INSPECT_SIGNAL => :inspect,
        EXECUTE_SIGNAL => :execute,
      )
    )
    INSPECT  = '[INSPECT]'.freeze
    SHUTDOWN = '[SHUTDOWN]'.freeze
    ACTION   = '[ACTION]'.freeze
    WAIT     = 'tmp/jobs/wait.txt'.freeze
    ACTIONS  = 'tmp/jobs/actions'.freeze
    REQUESTS = 'tmp/jobs/requests.txt'.freeze

    track_count_of :on_signal
    track_count_of :on_request
    track_count_of :on_response
    track_count_of :on_listen
    track_count_of :on_poll
    track_count_of :execute
    track_count_of :execute_error!
    track_count_of :perform
    track_count_of :perform_error!
    track_count_of :job_dequeue

    def self.steps
      %i(
        check_readiness
        restore_signals
        restore_requests
        setup_trapping
        setup_signaling
        setup_requesting
        setup_responding
        setup_listening
        setup_polling
        wait_for_termination
      )
    end

    def self.args
      {
        queue:           ['--queue=QUEUE',                              'Queue name processed (default to "default")'],
        listen_timeout:  ['--listen-timeout=LISTEN_TIMEOUT',   Float,   'Timeout in seconds when blocking on listen', greater_than: 0],
        poll_interval:   ['--poll-interval=POLL_INTERVAL',     Float,   'Polling interval in seconds',                greater_than: 0],
        server_interval: ['--server-interval=SERVER_INTERVAL', Float,   'Check interval for server requests/status',  greater_than: 0],
        max_pool_size:   ['--max-pool-size=MAX_POOL_SIZE',     Integer, 'Maximum number of HTTP clients',             greater_or_equal: 1],
        keep_jobs:       ['--keep-jobs=KEEP_JOBS',             Integer, 'Number of jobs to keep for inspection',      greater_or_equal: 0],
      }
    end

    def self.defaults
      max_pool_size = (Setting[:max_pool_size] / 2) - 1
      max_pool_size = 1 if max_pool_size < 1
      {
        queue:           ActiveJob::Base.default_queue_name,
        listen_timeout:  1,
        poll_interval:   10,
        server_interval: 20,
        max_pool_size:   max_pool_size,
        keep_jobs:       0
      }
    end

    protected

    def before_run
      STDOUT.sync = true
      $task_snapshot = proc{ snapshot }
      @host = ExtRails::Routes.base_url
      @signals = Queue.new
      @requests = Queue.new
      @responses = Queue.new
      @clients = Queue.new
      @jobs = []
      @job = nil
      @waited = nil
      @restored = Concurrent::AtomicFixnum.new
      @perform_error = nil
      @dequeue_mutex = Mutex.new
      # thread groups must be defined after context initialization, otherwise they'll use their own
      @executor = ThreadGroup.new(4)
      @dispatcher = ThreadGroup.new(options.max_pool_size)
      mkdir_p 'tmp/jobs/actions' if Rails.env.dev_or_test?
    end

    def around_run
      I18n.with_locale(:en) do
        Time.use_zone('UTC') do
          Rails.application.reloader.wrap do
            ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
              yield
            end
          end
        end
      end
    end

    def check_readiness
      start = Time.current
      sleep 1 while File.exist? WAIT
      sleep options.server_interval until Rails.env.dev_or_test? || server_available?
      @waited = (Time.current - start).to_i
    end

    def wait_for_termination
      @executor.wait_for_termination
      dump_requests unless Rails.env.dev_or_test?
      puts snapshot.except(:time, :thread, :shutdown, :job).pretty_hash
    end

    def restore_signals
      actions.each{ @signals << :execute }
    end

    def restore_requests
      @dumped_requests = if File.exist? REQUESTS
        Concurrent::Array.new(Pathname.new(REQUESTS).readlines(chomp: true).reject(&:blank?))
      else
        []
      end
    end

    def setup_trapping
      SIGNALS.each do |signal, symbol|
        trap(signal) do
          @signals << symbol
        end
      end
    end

    def setup_signaling
      post(name: 'signal') do
        until thread_shuttingdown?
          on_signal @signals.pop
          Thread.pass
        end
      end
    end

    def setup_requesting
      @dispatcher.post_all(name: 'request') do
        if (path = @dumped_requests.pop)
          sleep options.server_interval while server_request? path
          @restored.increment
        end
        client_ready!
        until thread_shuttingdown?
          @responses << on_request(**@requests.pop)
        end
      end
    end

    def setup_responding
      post(name: 'response') do
        until thread_shuttingdown?
          on_response @responses.pop
        end
      end
    end

    def setup_listening
      post(name: 'listen', priority: 1) do |pg_conn|
        channel = pg_conn.escape_identifier Job::NOTIFY_CHANNEL
        pg_conn.exec("LISTEN #{channel}")

        yield if block_given? # for testing

        until thread_shuttingdown?
          pg_conn.wait_for_notify(options.listen_timeout) do |_channel, _pid, message|
            queue_name, scheduled_at = Job.parse_notification(message)
            if queue_name == options.queue && scheduled_at.past?
              on_listen
            end
          end
        end
      ensure
        pg_conn.exec("UNLISTEN #{channel}")
        Thread.pass until pg_conn.notifies.nil?
      end
    end

    def setup_polling
      post(name: 'poll') do
        until thread_shuttingdown?
          on_poll
          sleep(options.poll_interval)
        end
      end
    end

    private

    def snapshot
      {
        time: Time.current.utc,
        thread: Thread.current[:name],
        waited: @waited,
        restored: @restored.value,
        shutdown: @executor.shuttingdown?,
        signals: @signals.size,
        actions: actions.size,
        clients: @clients.size,
        on_signal: on_signal_count,
        on_request: on_request_count,
        on_response: on_response_count,
        on_listen: on_listen_count,
        on_poll: on_poll_count,
        execute: execute_count,
        execute_error: execute_error_count,
        perform: perform_count,
        perform_error: perform_error_count,
        job_dequeue: job_dequeue_count,
        job: job_snapshot,
      }
    end

    def on_signal(signal)
      case signal
      when :shutdown then shutdown
      when :inspect  then puts inspect
      when :execute  then execute
      end
    end

    def shutdown
      puts_info SHUTDOWN
      until @dispatcher.shutdown?
        @dispatcher.shutdown!
        Thread.pass
      end
      @executor.shutdown!
    end

    def inspect
      <<~EOF.strip
        #{INSPECT}[#{self.class.name}]
        #{snapshot.pretty_hash}
        #{@jobs.map(&:pretty_hash).join("\n") if options.keep_jobs > 0}
      EOF
    end

    def execute
      started_at = Concurrent.monotonic_time
      file = actions.first
      action = file.readlines.first.strip
      klass, meth, args, opts = extract_ruby_call(action)
      klass.public_send(meth, *args, **opts)
    rescue Exception => exception
      execute_error!
    ensure
      file&.delete
      if exception
        puts_action_failure action, exception
      else
        total = (Concurrent.monotonic_time - started_at).seconds.ceil(3)
        puts_action_success action, total
      end
    end

    def execute_error!
      # use for count
    end

    def on_request(**request)
      begin
        response = nil
        HTTP.persistent(@host) do |http|
          (ctx = OpenSSL::SSL::SSLContext.new).verify_mode = OpenSSL::SSL::VERIFY_NONE
          response = http.post(request[:url], json: { job: request[:data] }, ssl_context: ctx).flush
          response = Jobs::RejectedError.new(response, request) unless response.status.job_accepted?
        end
      rescue Exception => exception
        response = JobError.new(exception, data: request)
      end
      perform_error! unless response.is_a? HTTP::Response
      response
    ensure
      client_ready!
    end

    def on_response(response)
      Notice.deliver! response unless response.is_a? HTTP::Response
    end

    def on_listen
      until thread_shuttingdown?
        break unless dequeue
      end
    end

    def on_poll
      until thread_shuttingdown?
        break unless dequeue
      end
    end

    def dequeue
      if @dequeue_mutex.try_lock
        if client_available? && job_dequeue
          client_busy!
          perform
          performed = true
        end
        @dequeue_mutex.unlock
      end
      performed
    end

    def job_dequeue
      if perform_error?
        until thread_shuttingdown? || server_available?
          sleep(options.server_interval)
        end
        @perform_error = false
      else
        @job = Job.dequeue
      end
    end

    def perform
      @requests << @job.request
      case options.keep_jobs
      when 0          then return
      when @jobs.size then @jobs.shift
      end
      @jobs << { time: Time.current.utc, thread: Thread.current[:name] }.with_keyword_access.merge!(job_snapshot)
    end

    def perform_error?
      @perform_error
    end

    def perform_error!
      @perform_error = true
      Thread.pass
    end

    def server_request?(path)
      Process.passenger.requests(threshold: options.server_interval).any?{ |request| request[:path] == path }
    end

    def server_available?
      Process.passenger.available?(threshold: options.server_interval)
    end

    def client_available?
      @clients.size > 0
    end

    def client_ready!
      @clients << true
    end

    def client_busy!
      @clients.pop
    end

    def job_snapshot
      @job ? { type: @job.class.name }.merge!(@job.except(:json_data)) : {}
    end

    def puts_action_success(action, total)
      Log.job_action(action, total)
      puts "[#{Time.current.utc}]#{MixTask::SUCCESS}[#{Process.pid}]#{ACTION} #{action}: #{distance_of_time total}".green
    end

    def puts_action_failure(action, exception)
      Notice.deliver! Jobs::ActionError.new(exception, data: { action: action })
      puts "[#{Time.current.utc}]#{MixTask::FAILURE}[#{Process.pid}]#{ACTION} #{action}".red
    end

    def actions
      Pathname.new(ACTIONS).children.sort_by(&:mtime)
    end

    def dump_requests
      requests = Process.passenger.requests(force: true)&.select_map do |request|
        next unless (path = request[:path]).match? Job.path_regex
        path
      end
      if requests.present?
        Pathname.new(REQUESTS).write(requests.join("\n"))
      else
        Pathname.new(REQUESTS).delete(false)
      end
    end

    def extract_ruby_call(action)
      klass, meth, args = action.partition(/\.\w+/)
      meth.delete_prefix! '.'
      args.delete_prefix! '('; args.delete_suffix! ')'
      args = "[#{args}]".to_args
      [klass.to_const!, meth.to_sym, args, args.extract_options!.symbolize_keys!]
    end

    def post(**options)
      @executor.post(**options) do
        Rails.application.reloader.wrap do
          ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
            ActiveRecord::Base.with_raw_connection do |pg_conn, ar_conn|
              ar_conn.cache{ yield pg_conn }
            end
          end
        end
      end
    end
  end
end
