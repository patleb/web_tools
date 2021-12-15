module Rescues
  class JavascriptsController < ActionController::API
    include ActionController::RequestForgeryProtection

    prepend_before_action :set_format
    protect_from_forgery with: :exception

    def create
      if USER_AGENT_PARSER.parse(request.user_agent).browser_array[UA[:hw_brand]] == 'Spider'
        head :forbidden
      else
        log Rescues::JavascriptError.new(*create_args)
        head :created
      end
    end

    private

    def create_args
      message, backtrace = create_params.values_at(:message, :backtrace)
      data = (create_params[:data]&.to_unsafe_h || {}).merge(user_ip: request.remote_ip, user_agent: request.user_agent)
      [message, backtrace, data]
    end

    def create_params
      @_create_params ||= params.require(:rescues_javascript).permit(:message, backtrace: [], data: {})
    end

    def set_format
      request.format = :json
    end
  end
end
