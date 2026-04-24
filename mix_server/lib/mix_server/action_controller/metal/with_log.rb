module ActionController::WithLog
  private

  def log(exception, subject: nil, **)
    unless exception.is_a? RescueError
      exception = Rescues::RailsError.new(exception, data: Rack::Utils.log_context(request))
    end
    if MixServer.config.notice_deliver?
      Notice.deliver! exception, subject: subject
    else
      Log.rescue(exception)
    end
  rescue Exception => e
    Log.rescue(e)
  end
end
