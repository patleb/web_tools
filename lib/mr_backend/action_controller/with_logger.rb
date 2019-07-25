class RailsError < RescueError
  def self.rescue_class
    RailsRescue
  end
end

module ActionController::WithLogger
  REQUEST_CONTEXT ||= %i(remote_ip method original_url content_type).freeze
  IGNORED_PARAMS ||= %w(controller action format).freeze
  OBJECT_INSPECT ||= /(#<[A-Za-z_][A-Za-z0-9_]*:)(0x.+)(>)/.freeze

  def log(exception, subject:, throttle_key: 'logger', throttle_duration: nil)
    return if Current.log_throttled

    exception_message = exception.message.try(:sub, OBJECT_INSPECT, '\1?\3').try(:gsub, /\d+/, '?')
    throttle_value = { type: exception.class.to_s, message: exception_message }
    status = Throttler.status(key: throttle_key, value: throttle_value, duration: throttle_duration)
    return if status[:throttled]

    Current.log_throttled = true
    context = log_context
    if status[:previous]
      context.merge! previous_exception: status[:previous].merge(count: status[:count])
    else
      context.merge! previous_exception: { count: 0 }
    end

    message = Notice.new.deliver! RailsError.new(exception, context), subject: subject do |message|
      Rails.logger.error message
    end

    yield message if block_given?
  end

  protected

  def log_context
    {
      request: REQUEST_CONTEXT.each_with_object({}){ |attr, memo| memo[attr] = request.send(attr) },
      params: request.filtered_parameters.except(*IGNORED_PARAMS, controller_name.singularize),
      headers: request.headers.env.select{ |header| header =~ /^HTTP_/ },
      session: session.try(:to_hash) || {},
      response: { status: response.status },
      host: Process.host.snapshot,
    }.merge!(Process.worker.self_and_siblings.each_with_object({}).with_index{ |(worker, memo), i|
      memo[:"worker_#{i}"] = worker.snapshot if Rails::Env.dev_or_test? && worker.name == 'ruby' # Rubymine
    })
  end
end
