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
      assert_field(group.fields_hash[:string],
        'string_field string_type',
        /Obligatoire.+String\*.+Longueur maximale 50.+tooltip/,
        '-',
        '<input type="text" name="string" class="input input-bordered" required="required" maxlength="50" id="string"></input>',
      )
      assert_field(group.fields_hash[:text],
        'text_field text_type',
        '<label>Text</label>',
        '-',
        %{<textarea name="text" class="textarea textarea-bordered" id="text">\n</textarea>},
      )
      assert_field(group.fields_hash[:lock_version],
        'lock_version_field hidden_type',
        false,
        0,
        '<input type="hidden" name="lock_version" class="input input-bordered" value="0" id="lock_version" autocomplete="off"></input>',
      )
      assert_field(group.fields_hash[:password],
        'password_field password_type',
        '<label>Password</label>',
        '-',
        '<input type="password" name="password" class="input input-bordered" id="password"></input>',
      )
      assert_field(group.fields_hash[:integer],
        'integer_field enum_type',
        '<label>Integer</label>',
        'Zero',
        '<select name="integer" class="input input-bordered" id="integer">'\
          '<option value=""> </option>'\
          '<option value="0" selected="selected">Zero</option>'\
          '<option value="1">One</option>'\
          '<option value="2">Two</option>'\
          '<option value="3">Three</option>'\
          '<option value="4">Four</option>'\
          '<option value="5">Five</option>'\
        '</select>',
      )
      assert group.fields_hash.reject{ |_, f| f.readonly? }.slice(:id, :deleted_at, :nested_record_name, :related_records_id).empty?
    end
  end

  test 'POST :new' do
    post "/model/#{model_name}/new", params: { model_name.underscore => { string: 'new-string', integer: 'one' } }

    assert Test::Extensions::RecordExtension.find_by(string: 'new-string', integer: 'one')
  end
end
