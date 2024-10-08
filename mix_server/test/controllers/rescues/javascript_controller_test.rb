require './test/test_helper'
require 'action_controller/metal/request_forgery_protection'

module Rescues
  class JavascriptControllerTest < ActionDispatch::IntegrationTest
    self.use_transactional_tests = false

    before do
      Throttler.clear
    end

    test 'catch CSRF error as bad request' do
      post '/_rescue_js', as: :json
      assert_response :bad_request
    end

    context 'without CSRF' do
      test 'log javascript error' do
        Rescues::JavascriptController.allow_forgery_protection = false
        assert_emails(1) do
          params = {
            rescue_js: {
              message: 'Method undefined',
              backtrace: caller,
              data: { text: 'Text' },
            }
          }
          post '/_rescue_js', params: params, as: :json
          assert_response :created
          assert_equal true, LogMessage.where('text_tiny LIKE ?', '%JavascriptError%').take.reported?

          post '/_rescue_js', params: params, as: :json
          assert_response :too_many_requests
          assert_equal 2, Global.read_multi(/throttler:rescue_js/).values.first[:count]
        end
        Rescues::JavascriptController.allow_forgery_protection = true
      end
    end
  end
end
