module ActionDispatch
  BAD_REQUEST_ERRORS = [
    EOFError,
    URI::InvalidURIError,
    ActionController::BadRequest,
    ActionDispatch::Http::MimeNegotiation::InvalidType,
    ActionController::InvalidAuthenticityToken,
  ]

  class ExceptionInterceptor
    def self.call(request, exception)
      unless exception.is_a? RescueError
        exception = Rescues::RackError.new(exception, data: Rack::Utils.log_context(request))
      end
      case exception.base_class
      when *BAD_REQUEST_ERRORS
        Log.rescue(exception)
      else
        Notice.deliver! exception
      end
    rescue Exception => e
      Log.rescue(e)
    end
  end
end

ActionDispatch::DebugExceptions.interceptors << ActionDispatch::ExceptionInterceptor
