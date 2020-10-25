module Rescues
  class JavascriptError < RescueError
    attr_reader :backtrace

    def initialize(message, backtrace, data)
      @name = self.class.name
      @message = message
      @backtrace = backtrace
      @data = data
    end

    def before_backtrace
      @message
    end
  end
end
