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
end
