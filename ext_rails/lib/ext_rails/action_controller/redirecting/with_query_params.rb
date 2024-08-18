MonkeyPatch.add{['actionpack', 'lib/action_controller/metal/redirecting.rb', 'b5e67d34b7f1f865af39f58efdf58c46ff271f25cfd3c499a03e45000cd8589e']}

module ActionController::Redirecting::WithQueryParams
  def redirect_to(options = {}, response_options = {})
    if options.is_a?(String) && (params = response_options.delete(:params))
      options = Rack::Utils.merge_url(options, params: params)
    end
    super(options, response_options)
  end
end
