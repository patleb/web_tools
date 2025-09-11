module MixJob
  class Watch < ActiveTask::Base
    # TERM --> by System Monitor
    # HUP  --> by Closing Terminal
    # INT  --> by Systemd / Ctrl-C / IDE
    SHUTDOWN_SIGNALS = ENV['DEBUGGER_HOST'] ? %w(TERM HUP): %w(TERM HUP INT)
    SHUTDOWN_SIGNAL  = 'TERM' # used in tests
    INSPECT_SIGNAL   = 'USR1'
    EXECUTE_SIGNAL   = 'USR2'
    SIGNALS = SHUTDOWN_SIGNALS.index_with(:shutdown).merge!(
      INSPECT_SIGNAL => :inspect,
      EXECUTE_SIGNAL => :execute,
    )
    INSPECT  = '[INSPECT]'
    SHUTDOWN = '[SHUTDOWN]'
    ACTION   = '[ACTION]'
    WAIT     = Rails.env.test? ? 'tmp/test/jobs/wait.txt'     : 'tmp/jobs/wait.txt'
    ACTIONS  = Rails.env.test? ? 'tmp/test/jobs/actions'      : 'tmp/jobs/actions'
    REQUESTS = Rails.env.test? ? 'tmp/test/jobs/requests.txt' : 'tmp/jobs/requests.txt'

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
        kill_timeout:    ['--kill-timeout=KILL_TIMEOUT',       Float,   'Kill timeout in seconds',                    greater_than: 0],
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
        kill_timeout:    60, # systemd timeout is by default 90s
        keep_jobs:       0
      }
    end

    protected

    def before_run
      STDOUT.sync = true
      $task_snapshot = proc{ snapshot }
      thread_channels :@signals, :@requests, :@responses
      @clients = Concurrent::AtomicFixnum.new
      @host = ExtRails::Routes.base_url
      @jobs = []
      @job = nil
      @waited = nil
      @restored = Concurrent::AtomicFixnum.new
      @perform_error = nil
      @dequeue_mutex = Mutex.new
      # thread groups must be defined after context initialization, otherwise they'll use their own
      @executor = ThreadGroup.new(max_threads: 4)
      @dispatcher = ThreadGroup.new(max_threads: options.max_pool_size)
      mkdir_p ACTIONS, verbose: false
    end

    def around_run
      I18n.with_locale(:en) do
        Time.use_zone('UTC') do
          yield
        end
      end
    end

    def check_readiness
      start = Time.current
      sleep 1 while File.exist? WAIT
      sleep options.server_interval until server_available? unless Rails.env.development?
      @waited = (Time.current - start).to_i
    end

    def wait_for_termination
      @executor.join_all
      dump_requests unless Rails.env.development?
      puts snapshot.except(:time, :thread, :shutdown, :job).pretty_hash
    end

    def restore_signals
      actions.each{ thread_send :@signals, :execute }
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
          thread_send :@signals, symbol
        end
      end
    end

    def setup_signaling
      post(name: 'signal') do
        thread_receive :@signals do |value|
          on_signal value
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
        thread_receive :@requests do |request|
          thread_send :@responses, on_request(request) do |response|
            on_response response
          end
        end
      end
    end

    def setup_responding
      post(name: 'response') do
        thread_receive :@responses do |value|
          on_response value
        end
      end
    end

    def setup_listening
      @listener = post(name: 'listen', priority: 1) do |pg_conn|
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
      @poller = post(name: 'poll') do
        until thread_shuttingdown?
          on_poll
          thread_sleep(options.poll_interval)
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
        clients: @clients.value,
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
      @executor.shutdown!
      @responses.close
      @requests.close
      @signals.close
      @dispatcher.kill_all(options.kill_timeout)
      Thread.pass until @dispatcher.shutdown?
      if @poller
        Thread.pass until @poller.dead? || @poller.asleep?
        @poller.kill
      end
      if @listener
        Thread.pass until @listener.dead? || @listener.asleep?
        @listener.kill
      end
    end

    def inspect
      <<~EOF.strip
        #{INSPECT}[#{self.class.name}]
        #{snapshot.pretty_hash}
        #{@jobs.map(&:pretty_hash).join("\n") if options.keep_jobs > 0}
      EOF
    end

    # NOTE need to bypass write buffer before sending signal to make sure the file is available
    # https://stackoverflow.com/questions/1429951/force-flushing-of-output-to-a-file-while-bash-script-is-still-running
    # https://linux.die.net/man/1/stdbuf
    def execute
      started_at = Concurrent.monotonic_time
      return unless (file = actions.first)
      return unless (action = file.readlines.first&.strip).present?
      klass, meth, args, opts = extract_ruby_call(action)
      klass.public_send(meth, *args, **opts)
    rescue Exception => exception
      execute_error!
    ensure
      file&.delete
      if exception
        puts_action_failure action, exception
      elsif action.present?
        total = (Concurrent.monotonic_time - started_at).seconds.ceil(3)
        puts_action_success action, total
      else
        puts_missing_action
      end
    end

    def execute_error!
      # use for count
    end

    def on_request(request)
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
          performed = perform
        end
        @dequeue_mutex.unlock
      end
      performed
    end

    def job_dequeue
      if perform_error?
        until thread_shuttingdown? || server_available?
          thread_sleep(options.server_interval)
        end
        @perform_error = false
      else
        @job = Job.dequeue
      end
    end

    def perform
      performed = true
      thread_send :@requests, @job.request do
        @job.dup.save!
        performed = @job = nil
      end
      case options.keep_jobs
      when 0          then return performed
      when @jobs.size then @jobs.shift
      end
      @jobs << { time: Time.current.utc, thread: Thread.current[:name] }.to_hwka.merge!(job_snapshot)
      performed
    end

    def perform_error?
      @perform_error
    end

    def perform_error!
      @perform_error = true
      Thread.pass
    end

    def server_request?(path)
      Process.passenger.requests(timeout: options.server_interval).any?{ |request| request[:path] == path }
    end

    def server_available?
      Process.passenger.available?(timeout: options.server_interval)
    end

    def client_available?
      @clients.value > 0
    end

    def client_ready!
      @clients.increment
    end

    def client_busy!
      @clients.decrement
    end

    def job_snapshot
      @job ? { type: @job.class.name }.merge!(@job.except(:json_data)) : {}
    end

    def puts_action_success(action, total)
      Log.job_action(action, total)
      puts "[#{Time.current.utc}]#{Rake::SUCCESS}[#{Process.pid}]#{ACTION} #{action} -- : #{distance_of_time total}".green
    end

    def puts_action_failure(action, exception)
      Notice.deliver! Jobs::ActionError.new(exception, data: { action: action })
      puts "[#{Time.current.utc}]#{Rake::FAILURE}[#{Process.pid}]#{ACTION} #{action}".red
    end

    def puts_missing_action
      puts "[#{Time.current.utc}]#{Rake::WARNING}[#{Process.pid}]#{ACTION} missing".yellow
    end

    def actions
      Pathname.new(ACTIONS).children.sort_by(&:mtime)
    end

    def dump_requests
      requests = Process.passenger.requests(force: true).select_map do |request|
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
      [klass.to_const!, meth.to_sym, args, args.extract_options!.to_hwka]
    end

    def post(**options)
      @executor.post(**options) do
        I18n.with_locale(:en) do
          Time.use_zone('UTC') do
            Job.with_raw_connection do |pg_conn, ar_conn|
              ar_conn.cache{ yield pg_conn }
            end
          end
        end
      end
    end
  end
end
