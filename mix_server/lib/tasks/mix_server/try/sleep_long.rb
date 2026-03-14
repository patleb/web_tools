module Try
  class SleepLong < ActiveTask::Base
    def sleep_long
      Kernel.sleep 12_005
    end
  end
end
