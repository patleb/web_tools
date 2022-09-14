ActionController::TestSession.prepend ActionDispatch::Request::Session::WithMemoizedAt

ActionController::TestCase.class_eval do
  include Devise::Test::ControllerHelpers if defined? Devise

  attr_reader :controller
  delegate :body, to: :response

  let(:controller_class){ base_name.constantize }
  let(:params){ {} }

  before do
    self.params = params
    Current.controller = controller
  end

  def self.controller(action_name, &block)
    ApplicationController.define_method action_name do
      if block_given?
        instance_eval(&block)
      else
        head :ok
      end
    end

    Rails.application.routes.disable_clear_and_finalize = true

    Rails.application.routes.draw do
      get "/#{action_name}" => "application##{action_name}"
    end
  end

  alias_method :old_setup_controller_request_and_response, :setup_controller_request_and_response
  def setup_controller_request_and_response
    self.class.controller_class = controller_class
    old_setup_controller_request_and_response
  end

  def reset_controller
    setup_controller_request_and_response
    @_memoized.delete('params')
    self.params = params
    Current.controller = controller
  end

  protected

  def params=(values)
    controller.params = values
  end

  def [](name)
    controller.send(:instance_variable_get, name)
  end

  def []=(name, value)
    controller.send(:instance_variable_set, name, value)
  end
end
