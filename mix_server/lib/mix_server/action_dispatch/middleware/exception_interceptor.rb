module ActionDispatch
  class ExceptionInterceptor
    def self.call(request, exception)
      unless exception.is_a? RescueError
        exception = Rescues::RackError.new(exception, data: Rack::Utils.log_context(request))
      end
      case exception.error
      when *ActionController::BAD_REQUEST_ERRORS
        # will be reported indirectly through LogLines::App
      else
        Notice.deliver! exception
      end
    rescue Exception => e
      Log.rescue(e)
    end
  end
end

ActionDispatch::DebugExceptions.interceptors << ActionDispatch::ExceptionInterceptor
