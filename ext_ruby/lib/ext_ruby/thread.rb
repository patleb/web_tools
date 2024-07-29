module Kernel
  def thread(*, abort_on_exception: true, priority: nil, **locals, &)
    thread = Thread.new(*, &)
    thread.abort_on_exception = abort_on_exception
    thread.priority = priority if priority
    locals.each{ |name, value| thread[name] = value }
    thread[:self] = thread
    thread
  end

  def thread_siblings
    Thread.current.siblings
  end

  def thread_sleep(timeout)
    Thread.current.sleep(timeout)
  end

  def thread_shuttingdown?
    Thread.current.shuttingdown?
  end

  def thread_channel(*names)
    names.each do |name|
      ivar(name, Thread::Queue.new)
    end
  end
  alias_method :thread_channels, :thread_channel

  def thread_receive(name)
    channel = ivar(name)
    until (value = channel.pop).nil?
      yield value
      Thread.pass
    end
  end

  def thread_send(name, value)
    ivar(name) << value
    Thread.pass
  rescue ClosedQueueError => error
    if block_given?
      yield value, error
    else
      # do nothing
    end
  end

  def thread_close(name)
    ivar(name).close
    Thread.pass
  end
end

class Thread
  def siblings
    list = group.list
    list.delete(self)
    list
  end

  def shuttingdown?
    group.shuttingdown?
  end

  def awake?
    !self[:sleep]
  end

  def asleep?
    !!self[:sleep]
  end

  def dead?
    !status
  end

  def sleep(timeout)
    self[:sleep] = true
    Kernel.sleep(timeout)
  ensure
    self[:sleep] = false
  end
end
