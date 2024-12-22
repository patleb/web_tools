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
      assert_field(group.fields_hash[:id],
        'id_field integer_type',
        '<label>Id</label>',
        '1',
        '1',
      )
      assert_field(group.fields_hash[:nested_record_name],
        'nested_record_name_field has_one_type association_type name_field string_type',
        '<label>Nested record</label>',
        '<a href="http://127.0.0.1:3333/model/test-related_record/5" class="link text-primary" rel="noopener">related to 1</a>',
        '<input type="text" name="name" class="input input-bordered" value="related to 1" through="nested_record" id="name"></input>',
      )
      assert_field(group.fields_hash[:lock_version],
        'lock_version_field hidden_type',
        false,
        1,
        '<input type="hidden" name="lock_version" class="input input-bordered" value="1" id="lock_version" autocomplete="off"></input>',
      )
      assert_field(group.fields_hash[:password],
        'password_field password_type',
        '<label>Password</label>',
        nil,
        '<input type="password" name="password" class="input input-bordered" id="password"></input>',
      )
      assert_field(group.fields_hash[:integer],
        'integer_field enum_type',
        '<label>Integer</label>',
        'One',
        '<select name="integer" class="select select-bordered" id="integer">'\
          '<option value=""> </option>'\
          '<option value="0">Zero</option>'\
          '<option value="1" selected="selected">One</option>'\
          '<option value="2">Two</option>'\
          '<option value="3">Three</option>'\
          '<option value="4">Four</option>'\
          '<option value="5">Five</option>'\
        '</select>',
      )
      assert group.fields_hash.reject{ |_, f| f.readonly? }.slice(:id, :deleted_at, :related_records_id).empty?
    end
  end

  test 'POST :edit' do
    post "/model/#{model_name}/1/edit", params: { model_name.underscore => {
      string: 'new-string',
      integer: 2,
      nested_record_attributes: { name: 'edited' },
    } }

    record = Test::Extensions::RecordExtension.find(1)
    assert_equal 'new-string', record.string
    assert_equal :two, record.integer
    assert_equal 'edited', record.nested_record.name
    assert_select 'input[name="test_extensions_record_extension[string]"][value="new-string"]'
    assert_select 'input[name="test_extensions_record_extension[nested_record_attributes][name]"][value="edited"]'
    assert_select 'input[name="test_extensions_record_extension[lock_version]"][value=2]'
    assert_select 'select[name="test_extensions_record_extension[integer]"] option[value="2"][selected]'
  end
end
