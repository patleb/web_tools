require './test/test_helper'
require 'action_controller/metal/request_forgery_protection'

module Rescues
  class JavascriptControllerTest < ActionDispatch::IntegrationTest
    it 'should catch CSRF error as bad request' do
      post '/_rescues/javascript', as: :json
      assert_response :bad_request
    end

    context 'without CSRF' do
      it 'should log javascript error' do
        Rescues::JavascriptController.allow_forgery_protection = false
        assert_emails(1) do
          params = {
            rescues_javascript: {
              message: 'Method undefined',
              backtrace: caller,
              data: { text: 'Text' },
            }
          }
          post '/_rescues/javascript', params: params, as: :json
          assert_response :created
          assert_equal true, LogMessage.where('text_tiny LIKE ?', '%JavascriptError%').take.reported?

          post '/_rescues/javascript', params: params, as: :json
          assert_response :created
          assert_equal 2, Global.read_multi(/^rack:attack:/).values.first
        end
        Rescues::JavascriptController.allow_forgery_protection = true
      end
    end
  end
end
