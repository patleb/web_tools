ActionDispatch::IntegrationTest.class_eval do
  include Devise::Test::IntegrationHelpers if defined? Devise

  class TestMethodAlreadyDefined < ::StandardError; end

  attr_accessor :current
  attr_accessor :result
  delegate :parsed_body, to: :response
  alias_method :body, :parsed_body

  def controller_assert(...)
    controller_test(...)
    assert_response :ok
  end

  def controller_refute(name, **request_options, &falsy)
    controller_assert(name, **request_options) do
      !instance_eval(&falsy)
    end
  end

  def controller_test(name, **request_options, &truthy)
    action_name, url = "test_#{name}", "/test/#{name}"
    controller_define(action_name) do
      if block_given? && instance_exec(url, action_name, &truthy)
        head :ok unless performed?
      else
        head :internal_server_error
      end
    end
    head url, **request_options
  end

  def controller_define(method_name, &block)
    require 'minitest/ext_rails/test_controller'

    raise TestMethodAlreadyDefined, method_name if ExtRails::TestController.method_defined? method_name
    (@controller_methods ||= Set.new) << method_name

    ExtRails::TestController.define_method(method_name, &block)
  end

  def [](name)
    controller.ivar(name)
  end

  def []=(name, value)
    controller.ivar(name, value)
  end

  def assert_recognizes(expected_options, *)
    expected_options = expected_options.with_indifferent_access
    super
  end

  module self::WithTeardown
    def teardown
      @controller_methods&.each do |method_name|
        next unless ExtRails::TestController.method_defined? method_name
        ExtRails::TestController.remove_method method_name
      end
      self.current = nil
      self.result = nil
      super
    end
  end
  prepend self::WithTeardown
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
