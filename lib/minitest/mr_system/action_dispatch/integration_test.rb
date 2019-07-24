ActionDispatch::IntegrationTest.class_eval do
  include Devise::Test::IntegrationHelpers if defined? Devise

  delegate :parsed_body, to: :response

  def with_routing
    yield app.routes
  ensure
    app.routes_reloader.reload!
  end
end
