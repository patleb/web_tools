# TODO https://www.ecalamia.com/blog/show-ip-api-nginx/
# TODO move javascript rescue code in this gem
class JavascriptRescuesController < ActionController::API
  include ActionController::RequestForgeryProtection

  protect_from_forgery with: :exception

  def create
    log error_class.new(*create_args)
    head :created
  end

  private

  def error_class
    ActiveSupport::Dependencies.safe_constantize((create_params[:exception] || '').camelize) || JavascriptError
  end

  def create_args
    message, backtrace = create_params.values_at(:message, :backtrace)
    data = (create_params[:data]&.to_unsafe_h || {}).merge(
      user_ip: request.remote_ip,
      user_agent: request.user_agent,
      host: Process.host.snapshot,
    )
    [message, backtrace, data]
  end

  def create_params
    @_create_params ||= params.require(:javascript_rescue).permit(:exception, :message, backtrace: [], data: {})
  end
end
