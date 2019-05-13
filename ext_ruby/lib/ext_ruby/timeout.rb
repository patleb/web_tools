# https://github.com/ruby-debug/ruby-debug-ide/issues/80
if defined? Debugger
  require 'timeout'
  module Timeout
    def timeout(sec, klass = nil, message = nil)
      yield(sec)
    end
    module_function :timeout
  end
end
