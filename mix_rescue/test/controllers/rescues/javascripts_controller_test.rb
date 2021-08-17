require './test/rails_helper'
require 'action_controller/metal/request_forgery_protection'

module Rescues
  class JavascriptsControllerTest < ActionDispatch::IntegrationTest
    it 'should raise on CSRF error' do
      MixRescue.with do |config|
        config.rescue_500 = false
        assert_emails(1) do
          assert_raise(ActionController::InvalidAuthenticityToken) do
            post '/_rescues/javascripts', as: :json
          end
          assert_equal true, LogMessage.where('text_tiny LIKE ?', '%RackError%').take.reported?
        end
      end
    end

    context 'without CSRF' do
      it 'should log javascript error' do
        Rescues::JavascriptsController.allow_forgery_protection = false
        assert_emails(1) do
          params = {
            rescues_javascript: {
              message: 'Method undefined',
              backtrace: caller,
              data: { text: 'Text' },
            }
          }
          post '/_rescues/javascripts', params: params, as: :json
          assert_response :created
          assert_equal true, LogMessage.where('text_tiny LIKE ?', '%JavascriptError%').take.reported?

          post '/_rescues/javascripts', params: params, as: :json
          assert_response :created
          assert_equal 2, Global.read_multi(/^rack:attack:/).values.first
        end
        Rescues::JavascriptsController.allow_forgery_protection = true
      end
    end
  end
end
