require './test/test_helper'
require './mix_admin/test/support/admin_controller_context'

class AdminController::EditTest < ActionDispatch::IntegrationTest
  include AdminControllerContext

  test 'GET :edit' do
    assert_equal '/model/:model_name/:id/edit', MixAdmin.routes[:edit]
    assert_equal "/model/#{model_name}/1/edit", MixAdmin::Routes.edit_path(model_name: model_name, id: 1)

    get "/model/#{model_name}/1/edit"

    assert_response :ok
    assert_layout :member, :edit, path: '/1/edit'
    assert_group 'Record extension #1' do |group|
      id_field = group.fields_hash[:id]
      assert_equal 'id_field integer_type', id_field.css_class
      assert_equal 'Id', id_field.label
      assert_equal '1', id_field.pretty_value
    end
  end

  test 'POST :edit' do
    post "/model/#{model_name}/1/edit", params: { model_name.underscore => {
      string: 'new-string',
      nested_record_attributes: { name: 'edited' },
    } }

    record = Test::Extensions::RecordExtension.find(1)
    assert_equal 'new-string', record.string
    assert_equal 'edited', record.nested_record.name
    assert_select 'input[name="test_extensions_record_extension[string]"][value="new-string"]'
    assert_select 'input[name="test_extensions_record_extension[nested_record_attributes][name]"][value="edited"]'
  end
end
