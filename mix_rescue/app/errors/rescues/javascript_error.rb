module Rescues
  class JavascriptError < RescueError
    attr_reader :backtrace

    def initialize(message, backtrace, data)
      super(self, data: data)
      @message = message
      @backtrace = backtrace
    end
  end
end
