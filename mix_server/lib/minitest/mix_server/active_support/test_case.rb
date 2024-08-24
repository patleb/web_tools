ActiveSupport::TestCase.class_eval do
  alias_method :run_without_server, :run
  def run(...)
    Server.current
    run_without_server(...)
  end
end
