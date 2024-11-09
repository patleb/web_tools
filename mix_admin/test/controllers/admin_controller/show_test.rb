require './test/test_helper'
require './mix_admin/test/support/admin_controller_context'

class AdminController::ShowTest < ActionDispatch::IntegrationTest
  include AdminControllerContext

  test 'redirect to :root_path on empty :model_name' do
    get '/model//1'
    assert_redirected_to root_path
  end

  test 'redirect to :root_path on unknown model' do
    get '/model/unknown/1'
    assert_redirected_to root_path
  end

  test 'redirect to :root_path on bad id' do
    get "/model/#{model_name}/-1"
    assert_redirected_to root_path
  end

  context 'denied model' do
    let(:model_denied){ true }

    test 'redirect to :root_path on denied model' do
      get "/model/#{model_name}/1"
      assert_redirected_to root_path
    end
  end

  context 'denied presenter' do
    let(:presenter_denied){ true }

    test 'redirect to :root_path on denied presenter' do
      get "/model/#{model_name}/1"
      assert_redirected_to root_path
    end
  end

  test 'GET :show' do
    assert_equal '/model/:model_name/:id', MixAdmin.routes[:show]
    assert_equal "/model/#{model_name}/1", MixAdmin::Routes.show_path(model_name: model_name, id: 1)

    get "/model/#{model_name}/1"

    assert_response :ok
    assert_layout :member, :show, path: '/1'
    assert_group 'Record extension #1' do |group|
      assert_field(group.fields_hash[:id],
        'id_field integer_type',
        '<label>Id</label>',
        '1'
      )
      assert_field(group.fields_hash[:nested_record_name],
        'nested_record_name_field has_one_type association_type name_field string_type',
        '<label>Nested record</label>',
        '<a href="http://127.0.0.1:3333/model/test-related_record/5" class="link text-primary" rel="noopener">related to 1</a>',
      )
      assert_field(group.fields_hash[:related_records_id],
        'related_records_id_field has_many_type array_type association_type id_field integer_type',
        '<label>Related records</label>',
        '- <a href="http://127.0.0.1:3333/model/test-related_record/1" class="link text-primary" rel="noopener">1</a>&nbsp;<br>'\
        '- <a href="http://127.0.0.1:3333/model/test-related_record/2" class="link text-primary" rel="noopener">2</a>&nbsp;<br>'\
        '- <a href="http://127.0.0.1:3333/model/test-related_record/3" class="link text-primary" rel="noopener">3</a>&nbsp;<br>'\
        '- <a href="http://127.0.0.1:3333/model/test-related_record/5" class="link text-primary" rel="noopener">5</a>&nbsp;',
      )
      assert_field(group.fields_hash[:integer],
        'integer_field enum_type',
        '<label>Integer</label>',
        'One'
      )
      assert group.fields_hash.slice(:deleted_at, :lock_version, :password).empty?
    end
  end
end
