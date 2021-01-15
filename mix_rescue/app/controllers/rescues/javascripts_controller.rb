# TODO https://www.ecalamia.com/blog/show-ip-api-nginx/
module Rescues
  class JavascriptsController < ActionController::API
    include ActionController::RequestForgeryProtection

    protect_from_forgery with: :exception

    def create
      log Rescues::JavascriptError.new(*create_args)
      head :created
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
  end
end
