module ActionController::WithLogger
  REQUEST_CONTEXT ||= %i(remote_ip method original_url content_type).freeze
  IGNORED_PARAMS ||= %w(controller action format).freeze

  def log(exception, subject: nil)
    return if Current.error_logged

    Current.error_logged = true
    unless exception.is_a? RescueError
      exception = RailsError.new(exception, log_context)
    end

    message = Notice.deliver! exception, subject: subject, logger: true
    yield message if block_given?
    message
  end

  protected

  def log_context
    {
      request: REQUEST_CONTEXT.each_with_object({}){ |attr, memo| memo[attr] = request.send(attr) },
      params: request.filtered_parameters.except(*IGNORED_PARAMS, controller_name.singularize),
      headers: request.headers.env.select{ |header| header =~ /^HTTP_/ },
      session: session.try(:to_hash) || {},
      host: Process.host.snapshot,
    }.merge!(Process.worker.self_and_siblings.each_with_object({}).with_index{ |(worker, memo), i|
      if !Rails.env.dev_or_test? || (Rails.env.dev_or_test? && worker.name == 'ruby') # Rubymine
        memo[:"worker_#{i}"] = worker.snapshot
      end
    })
  end
end
