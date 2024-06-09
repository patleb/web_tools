ActionDispatch::IntegrationTest.class_eval do
  class TestMethodAlreadyDefined < ::StandardError; end

  include Devise::Test::IntegrationHelpers if defined? Devise

  attr_accessor :current
  delegate :parsed_body, to: :response
  alias_method :body, :parsed_body

  def controller_assert(...)
    controller_test(...)
    assert_response :ok
  end

  def controller_refute(action_name, **request_options, &block)
    controller_assert(action_name, **request_options) do
      !instance_eval(&block)
    end
  end

  def controller_test(action_name, **request_options, &block)
    require 'minitest/ext_rails/test_controller'

    method_name = "test_#{action_name}"
    raise TestMethodAlreadyDefined, method_name if ExtRails::TestController.method_defined? method_name
    (@controller_methods ||= Set.new) << method_name

    ExtRails::TestController.define_method(method_name) do
      if block_given? && instance_eval(&block)
        head :ok unless performed?
      else
        head :internal_server_error
      end
    end
    head "/test/#{action_name}", **request_options
  end

  alias_method :teardown_without_current, :teardown
  def teardown
    @controller_methods&.each do |method_name|
      next unless ExtRails::TestController.method_defined? method_name
      ExtRails::TestController.remove_method method_name
    end
    self.current = nil
    teardown_without_current
  end

  def [](name)
    controller.send(:instance_variable_get, name)
  end

  def []=(name, value)
    controller.send(:instance_variable_set, name, value)
  end
end

ActionDispatch::Integration::Session.class_eval do
  alias_method :old_process, :process
  def process(...)
    old_process(...)
    Current.controller = controller
    Current.view = controller.helpers
  end
end

Current.class_eval do
  def reset
    $test.current = attributes if $test.is_a? ActionDispatch::IntegrationTest
    super
  end
end
