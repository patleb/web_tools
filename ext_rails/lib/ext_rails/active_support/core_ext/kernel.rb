module Kernel
  module_function

  alias_method :require_without_profile, :require
  class << self
    alias_method :require_without_profile, :require
  end

  def require(path)
    if ENV['RAILS_PROFILE']
      if (result = Benchmark.realtime{ require_without_profile(path) }) > 0.005
        $profile_dependencies << "#{'%.5f' % result} #{path}"
      end
    else
      require_without_profile(path)
    end
  end

  def debug_locks
    ActionDispatch::DebugLocks.new(nil).send(:render_details, nil)
  end

  def let_stub(method_name, let_name, &block)
    mod = Module.new do
      define_method method_name do |*args, **opts|
        return super(*args, **opts) unless $test.try(let_name)
        instance_exec(*args, **opts, &block)
      end
    end
    prepend mod
  end
end
