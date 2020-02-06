module Notice::WithRescue
  def deliver!(exception, **)
    message = super
    if exception.class.respond_to? :rescue_class
      exception.class.rescue_class.enqueue exception, message
    else
      Rescue.enqueue exception, message
    end
    message
  end
end

Notice.prepend Notice::WithRescue
