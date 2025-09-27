module ActionController
  BAD_REQUEST_ERRORS = [
    EOFError,
    URI::InvalidURIError,
    Rack::QueryParser::InvalidParameterError,
    ActionController::BadRequest,
    ActionController::UnknownFormat,
    ActionDispatch::Http::MimeNegotiation::InvalidType,
    ActionDispatch::Http::Parameters::ParseError,
  ]

  module WithErrors
    extend ActiveSupport::Concern

    SKIP_CALLBACK_ACTIONS = ActionController::WithStatus.public_instance_methods

    included do
      _process_action_callbacks.each do |callback|
        public_send "skip_#{callback.kind}_action", callback.filter, only: SKIP_CALLBACK_ACTIONS
      end

      rescue_from Exception, with: :render_500 if MixServer.config.render_500
      rescue_from ActiveRecord::QueryCanceled, with: :render_408
      rescue_from *BAD_REQUEST_ERRORS, with: :render_400
    end
  end
end
