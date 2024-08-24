require './test/test_helper'

Rpc::Function.class_eval do
  private

  alias_method :old_select_function, :select_function
  def select_function(sql)
    $test.sql ? old_select_function($test.sql) : old_select_function(sql)
  end
end

module Rpc
  class FunctionsControllerTest < ActionDispatch::IntegrationTest
    self.file_fixture_path = Gem.root('mix_rpc').join('test/fixtures/files').to_s
    self.use_transactional_tests = false

    let(:sql){ false }

    around do |test|
      Rpc::FunctionsController.allow_forgery_protection = false
      MixRpc.with do |config|
        config.yml_path = Pathname.new(file_fixture_path).join('rpc.yml')
        test.call
      end
      Rpc::FunctionsController.allow_forgery_protection = true
    end

    test '#call healthcheck' do
      post '/rpc/healthcheck', as: :json
      assert_response :ok
      assert_equal true, ActiveSupport::JSON.decode(response.body)
    end

    test '#call not_found' do
      post '/rpc/not_found', params: { rpc_function: {} }
      assert_response :not_found
      assert_equal :json, request.format.symbol
    end

    { 'unknown function' => 'SELECT rpc.unknown()',
      'unknown argument' => 'SELECT rpc.healthcheck(1)',
      'invalid sql' => 'invalid SELECT rpc.healthcheck()',
    }.each do |type, sql|
      context type do
        let(:sql){ sql }

        test '#call not_acceptable' do
          post '/rpc/healthcheck', params: { rpc_function: {} }, as: :json
          assert_response :not_acceptable
          assert_includes LogMessage.first.text, ActiveSupport::JSON.decode(response.body)['error']
        end
      end
    end
  end
end
