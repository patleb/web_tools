# https://github.com/ruby-debug/ruby-debug-ide/issues/80
if ENV['DEBUGGER_HOST']
  require 'timeout'
  module Timeout
    def timeout(sec, klass = nil, message = nil)
      yield(sec)
    end
    module_function :timeout
  end
end
