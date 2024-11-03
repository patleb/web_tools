require './test/test_helper'
require './mix_admin/test/support/admin_controller_context'

class AdminController::NewTest < ActionDispatch::IntegrationTest
  include AdminControllerContext

  test 'GET :new' do
    assert_equal '/model/:model_name/new', MixAdmin.routes[:new]
    assert_equal "/model/#{model_name}/new", MixAdmin::Routes.new_path(model_name: model_name)

    get "/model/#{model_name}/new"

    assert_response :ok
    assert_layout :collection, :new, path: '/new'
    assert_group 'Nouveau(elle) Record extension' do |group|
      string_field = group.fields_hash[:string]
      assert_nil group.fields_hash[:id]
      assert_equal 'string_field string_type', string_field.css_class
      assert_equal 'String', string_field.label
      assert_equal '-', string_field.pretty_value
      assert_equal "<input type='text' name='string' class='input input-bordered' required='required' id='string'></input>",
        string_field.pretty_input.gsub("\"", "'")
    end
  end

  test 'POST :new' do
    post "/model/#{model_name}/new", params: { model_name.underscore => { string: 'new-string' } }

    assert Test::Extensions::RecordExtension.find_by(string: 'new-string')
  end
end
