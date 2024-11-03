require './test/test_helper'
require './mix_admin/test/support/admin_controller_context'

class AdminController::RestoreTest < ActionDispatch::IntegrationTest
  include AdminControllerContext

  test 'POST :restore' do
    record = model_klass.find(2)
    record.discard!
    refute model_klass.exists? id: 2

    post "/model/#{model_name}/_restore", params: { _restore: true, ids: [2] }

    assert model_klass.exists? id: 2
  end
end
