module Try
  class RaiseException < ActiveTask::Base
    def raise_exception
      raise StandardError, 'Exception message'
    end
  end
end
