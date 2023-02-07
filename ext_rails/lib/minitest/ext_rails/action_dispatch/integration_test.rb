ActionDispatch::IntegrationTest.class_eval do
  include Devise::Test::IntegrationHelpers if defined? Devise

  delegate :parsed_body, to: :response
  alias_method :body, :parsed_body

  def with_routing
    yield app.routes
  ensure
    app.routes_reloader.reload!
  end

  def [](name)
    controller.send(:instance_variable_get, name)
  end

  def []=(name, value)
    controller.send(:instance_variable_set, name, value)
  end
end
