module MixJob::WatchMock
  extend ActiveSupport::Concern

  prepended do
    include Minitest::Assertions

    delegate :assertions, :assertions=, to: :$test
    delegate :job_data, :actions, :good_actions, :bad_actions, to: :$test, prefix: ''

    attr_reader :_output
  end

  def puts_info(tag, text = nil)
    @_output ||= ''
    @_output << tag.to_s << "\n"
    @_output << text.to_s << "\n" if text
    super
  end

  def puts(obj = '', *arg)
    @_output ||= ''
    @_output << obj.to_s << "\n"
    super
  end

  protected

  def before_run
    @_output = ''
    super
    @executor.timeout(1, kill_on_expired: true) do |expired|
      puts inspect if expired
    end
  end

  def setup_listening
    super{ @_listen_connected = true }
  end

  def wait_for_termination
    test_wait_for_termination if test_wait_for_termination?
    super
  end

  def after_run
    send("test_#{options.goto || options.test}") unless test_wait_for_termination?
    super
  end

  private

  def test_wait_for_termination?
    options.goto == 'wait_for_termination'
  end

  def test_restore_signals
    assert_equal _actions.size, @signals.size

    actions.each(&:delete)
    shutdown
  end

  def test_setup_trapping
    signals = self.class::SIGNALS.keys
    signals.each{ |signal| Process.kill(signal, Process.pid) }
    assert_until(signals.size){ @signals.size }

    shutdown
  end

  def test_setup_signaling
    _signal :inspect
    assert_until(1){ _output.scan(self.class::INSPECT).size }
    assert_includes  _output, self.class.name
    assert_includes  _output, 'waited: 0'

    _actions.each do |action|
      Pathname.new("#{self.class::ACTIONS}/#{Time.current.to_nanoseconds}.rb").write(action)
      _signal :execute
    end
    assert_after(_actions.size)    { execute_count }
    assert_after(_bad_actions.size){ execute_error_count }
    assert_after(_bad_actions.size){ ActionMailer::Base.deliveries.size }
    assert_until(_actions.size)    { _output.scan(self.class::ACTION).size }
    assert_equal _good_actions.size, _output.scan(MixTask::SUCCESS).size
    assert_equal _bad_actions.size,  _output.scan(MixTask::FAILURE).size
    _bad_actions.values.each do |exception|
      assert_equal true, LogMessage.where('text_tiny LIKE ?', "%#{exception}%").take.reported?
    end

    _signal :shutdown
    assert_after(2 + _actions.size){ on_signal_count }
    assert_until(1){ _output.scan(self.class::SHUTDOWN).size }

    wait_for_termination
  end

  def test_setup_listening
    assert_until{ @_listen_connected }
    _broadcast
    assert_until(1){ on_listen_count }

    _trigger
    assert_until(2){ on_listen_count }

    _shutdown
  end

  def test_setup_polling
    @dequeue_mutex.synchronize do
      _enqueue
      _enqueue :server_error
      _enqueue :client_error
    end
    assert_until(0){ @clients.size }
    assert_after(3){ perform_count }
    assert_after(type: 'Job', result: 'success'){ @jobs.shift.slice(:type, :result) }
    assert_after(type: 'Job', result: 'server_error'){ @jobs.shift.slice(:type, :result) }
    assert_after(type: 'Job', result: 'client_error'){ @jobs.shift.slice(:type, :result) }
    assert_after(3){ on_request_count }
    assert_after(3){ on_response_count }
    assert_after(2){ perform_error_count }
    assert_until(2){ ActionMailer::Base.deliveries.size }

    _shutdown
  end

  def test_wait_for_termination
    assert_until{ @_listen_connected }
    @dequeue_mutex.synchronize do
      _broadcast
      _broadcast(1.minute.from_now)
      _trigger
    end
    assert_until(2){ on_listen_count }

    _enqueue
    assert_after(1){ perform_count }
    assert_after(1){ on_request_count }
    assert_until(1){ on_response_count }

    _signal :inspect
    _signal :execute
    assert_after(1){ _output.scan(self.class::INSPECT).size }
    assert_after(2){ on_signal_count }
    assert_after(1){ execute_count }
    assert_after(1){ execute_error_count }
    assert_after(1){ ActionMailer::Base.deliveries.size }
    assert_until(1){ _output.scan(self.class::ACTION).size }

    @clients.pop
    _enqueue
    assert_until(4){ on_listen_count }
    _dequeue

    _signal :shutdown
    assert_after(1){ perform_count }
    assert_after(1){ on_request_count }
    assert_after(1){ on_response_count }
    assert_after(3){ on_signal_count }
    assert_until(1){ _output.scan(self.class::SHUTDOWN).size }
  end

  def test_not_dequeue_on_error
    assert_until{ @_listen_connected }

    _enqueue :client_error
    assert_after(1){ on_listen_count }
    assert_after(1){ perform_error_count }
    assert_until(1){ ActionMailer::Base.deliveries.size }

    _enqueue
    assert_after(2){ on_listen_count }
    assert_until{ !perform_error? }

    _broadcast
    assert_after(3){ on_listen_count }
    assert_after(1){ perform_error_count }
    assert_until(2){ on_response_count }

    _shutdown
  end

  def _shutdown
    _signal :shutdown
    wait_for_termination
  end

  def _signal(type)
    Process.kill(self.class.const_get("#{type.upcase}_SIGNAL"), Process.pid)
  end

  def _broadcast(scheduled_at = 1.second.ago)
    queue_i = Job.queue_names[ActiveJob::Base.default_queue_name]
    ActiveRecord::Base.with_raw_connection do |pg_conn|
      # UUID needed since postgres might group the same payloads with the same scheduled_at with second precision
      pg_conn.exec("SELECT pg_notify('#{Job::NOTIFY_CHANNEL}', '#{queue_i},#{scheduled_at},#{SecureRandom.uuid}');")
    end
  end

  def _trigger
    _enqueue
    _dequeue
  end

  def _enqueue(result = nil)
    Job.enqueue(_job_data(result))
  end

  def _dequeue
    Job.dequeue
  end
end
