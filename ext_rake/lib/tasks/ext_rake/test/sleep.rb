module ExtRake
  module Test
    class Sleep < ActiveTask::Base
      def self.steps
        [:sleep]
      end

      def sleep
        Kernel.sleep 5
      end
    end
  end
end
