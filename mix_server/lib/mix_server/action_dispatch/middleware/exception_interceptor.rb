module ActionDispatch
  BAD_REQUEST_ERRORS = [
    EOFError,
    URI::InvalidURIError,
    Rack::QueryParser::InvalidParameterError,
    ActionController::BadRequest,
    ActionController::UnknownFormat,
    ActionDispatch::Http::MimeNegotiation::InvalidType,
    ActionDispatch::Http::Parameters::ParseError,
    ActionController::InvalidAuthenticityToken,
  ]

  class ExceptionInterceptor
    def self.call(request, exception)
      unless exception.is_a? RescueError
        exception = Rescues::RackError.new(exception, data: Rack::Utils.log_context(request))
      end
      case exception.error
      when *BAD_REQUEST_ERRORS
        # will be reported indirectly through LogLines::App
        Log.rescue_not_reportable(exception)
      else
        Notice.deliver! exception
      end
    rescue Exception => e
      Log.rescue(e)
    end
  end
end

ActionDispatch::DebugExceptions.interceptors << ActionDispatch::ExceptionInterceptor
