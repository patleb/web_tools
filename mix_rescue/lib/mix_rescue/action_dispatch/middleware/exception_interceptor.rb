module ActionDispatch
  class ExceptionInterceptor
    def self.call(request, exception)
      unless exception.is_a? RescueError
        exception = Rescues::RackError.new(exception, data: Rack::Utils.log_context(request))
      end
      Notice.deliver! exception
    rescue Exception => e
      Log.rescue(e)
    end
  end
end

ActionDispatch::DebugExceptions.interceptors << ActionDispatch::ExceptionInterceptor
