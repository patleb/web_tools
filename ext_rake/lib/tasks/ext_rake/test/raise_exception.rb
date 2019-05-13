module ExtRake
  module Test
    class RaiseException < ActiveTask::Base
      def self.steps
        [:raise_exception]
      end

      def raise_exception
        raise StandardError, 'Exception message'
      end
    end
  end
end
