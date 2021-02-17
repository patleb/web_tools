module Kernel
  def debug_locks
    ActionDispatch::DebugLocks.new(nil).send(:render_details, nil)
  end
end
