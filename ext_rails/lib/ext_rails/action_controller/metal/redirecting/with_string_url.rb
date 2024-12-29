MonkeyPatch.add{['actionpack', 'lib/action_controller/metal/redirecting.rb', '0a2a3c411b162e5b21cd5f27e4bc0eec6784b20af9858abdf268ef2ca3b59c2e']}

module ActionController::Redirecting::WithStringUrl
  def redirect_to(options = {}, response_options = {})
    if options.is_a? String
      if (params = response_options.delete(:params))
        options = Rack::Utils.merge_url(options, params: params)
      end
      if ExtRails::Routes.url_for(options) == request.original_url
        return
      end
    end
    super(options, response_options)
  end
end
