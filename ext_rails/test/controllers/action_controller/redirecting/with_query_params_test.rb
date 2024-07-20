require './test/test_helper'

class ActionController::Redirecting::WithQueryParamsTest < ActionDispatch::IntegrationTest
  let(:params){ { a: 1, b: [2, 3] } }

  test '#redirect_to' do
    controller_test :redirect_to do |url|
      redirect_to url, params: $test.params
    end
    assert_redirected_to "/test/redirect_to?#{params.to_query}"
  end
end
