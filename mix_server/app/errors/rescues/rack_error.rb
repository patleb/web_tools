# frozen_string_literal: true

module Rescues
  class RackError < RescueError
    def message
      super.gsub(/"(x_csrf|_csrf_token)": "[^"]+"/, '"\1": "*"')
    end
  end
end
