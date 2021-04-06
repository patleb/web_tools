module Rpc
  class FunctionError < RescueError
    def initialize(function)
      @message = function.error_message
      super(data: function.slice(:id, :params))
    end
  end
end
