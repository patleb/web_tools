require 'rack/utils'

module Rack::Utils
  REQUEST_CONTEXT ||= %i(remote_ip method path format content_type)
  IGNORED_PARAMS  ||= %w(controller action format)

  def self.log_context(request)
    context = REQUEST_CONTEXT.each_with_object(variant: request.variant[0]&.to_s) do |k, h|
      h[k] = request.public_send(k)&.to_s
    end
    params = request.filtered_parameters.except(*IGNORED_PARAMS, request.controller_class.try(:controller_path))
    cookies = request.cookies.try(:select){ |k, _| k.start_with?('_') && !k.end_with?('_session') } || {},
    { request: context.compact, params: params, cookies: cookies }
  rescue Exception
    {}
  end
end
