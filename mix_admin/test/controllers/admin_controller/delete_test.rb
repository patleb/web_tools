require './test/test_helper'
require './mix_admin/test/support/admin_controller_context'

class AdminController::DeleteTest < ActionDispatch::IntegrationTest
  include AdminControllerContext

  test 'GET :delete' do
    assert_equal '/model/:model_name/:id/delete', MixAdmin.routes[:delete]
    assert_equal "/model/#{model_name}/2/delete", MixAdmin::Routes.delete_path(model_name: model_name, id: 2)

    get "/model/#{model_name}/2/delete"

    assert_response :ok
    assert_layout :member, :delete, path: '/2/delete'
    assert_selects(
      "form.delete_records[action$='/model/#{model_name}/2/delete'][data-remote=true][method=post]",
      'input[name="ids[]"][value=2][type=hidden][multiple]',
      'a.link.link-primary',
      'input[name=_trash]',
      'input[name=_delete]',
      'input[name=_cancel]',
    )
  end

  test 'GET :delete with restrictions' do
    get "/model/#{model_name}/1/delete"

    assert_response :ok
    assert_selects(
      "form.delete_records[action$='/model/#{model_name}/1/delete'][data-remote=true][method=post]",
      'a.link.link-error',
      'input[name=_cancel]',
    )
  end

  test 'GET bulk :delete' do
    ids = { ids: [1, 2] }
    assert_equal "/model/#{model_name}/_bulk/delete?#{ids.to_query}", MixAdmin::Routes.delete_path(model_name: model_name, **ids)

    get "/model/#{model_name}/_bulk/delete", params: ids

    assert_response :ok
    assert_layout :collection, :delete, path: '/_bulk/delete', bulk: true
    assert_selects(
      "form.delete_records[action$='/model/#{model_name}/_bulk/delete'][data-remote=true][method=post]",
      'input[name="ids[]"][value=2][type=hidden][multiple]',
      'a.link.link-error',
      'a.link.link-primary',
      'input[name=_trash]',
      'input[name=_delete]',
      'input[name=_cancel]',
    )
  end

  test 'redirect to :root_path on empty blank bulk' do
    get "/model/#{model_name}/_bulk/delete"
    assert_redirected_to root_path
  end
end
