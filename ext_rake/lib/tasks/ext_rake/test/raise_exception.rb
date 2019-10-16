module ExtRake
  module Test
    class RaiseException < ActiveTask::Base
      def raise_exception
        raise StandardError, 'Exception message'
      end
    end
  end
end
