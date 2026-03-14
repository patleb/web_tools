module Try
  class Message < ::StandardError
    def backtrace
      caller
    end
  end
end
