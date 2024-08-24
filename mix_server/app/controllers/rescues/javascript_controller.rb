module Rescues
  class JavascriptController < LibApiController
    before_action :throttle

    def create
      if browser_bot?
        head :forbidden
      else
        log Rescues::JavascriptError.new(*create_args)
        head :created
      end
    end

    private

    def throttle
      key = ['rescues_javascript', request.remote_ip, user_agent]
      if Throttler.limit? key: key, value: create_params[:message].squish_all(256), within: 1.day
        head :too_many_requests
      end
    end

    def create_args
      @create_args ||= begin
        message, backtrace = create_params.values_at(:message, :backtrace)
        data = (create_params[:data]&.to_unsafe_h || {}).merge(user_ip: request.remote_ip, user_agent: request.user_agent)
        [message, backtrace, data]
      end
    end

    def create_params
      @_create_params ||= params.require(:rescues_javascript).permit(:message, backtrace: [], data: {})
    end
  end
end
