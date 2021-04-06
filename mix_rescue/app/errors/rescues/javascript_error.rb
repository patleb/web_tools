module Rescues
  class JavascriptError < RescueError
    def initialize(message, backtrace, data)
      @message = message
      @backtrace = backtrace
      super(self, data: data)
    end
  end
end
