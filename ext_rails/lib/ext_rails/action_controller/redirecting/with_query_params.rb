module ActionController::Redirecting::WithQueryParams
  def redirect_to(options = {}, response_options = {})
    if options.is_a?(String) && (params = response_options.delete(:params))
      options = Rack::Utils.merge_url(options, params: params)
    end
    super(options, response_options)
  end
end
