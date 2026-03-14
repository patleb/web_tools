module Try
  class Sleep < ActiveTask::Base
    def sleep
      Kernel.sleep 5
    end
  end
end
