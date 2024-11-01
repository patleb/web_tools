require './test/test_helper'
require './mix_admin/test/support/admin_controller_context'

class AdminController::ShowTest < ActionDispatch::IntegrationTest
  include AdminControllerContext

  context '#show' do
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

    test 'render :show' do
      assert_equal '/model/:model_name/:id', MixAdmin.routes[:show]
      assert_equal "/model/#{model_name}/1", MixAdmin::Routes.show_path(model_name: model_name, id: 1)

      get "/model/#{model_name}/1"

      assert_response :ok
      assert_layout :member, :show, path: '/1'
      assert_group 'Record extension #1' do |group|
        id_field = group.fields_hash[:id]
        assert_equal 'id_field integer_type', id_field.css_class
        assert_equal 'Id', id_field.label
        assert_equal '1', id_field.pretty_value
      end
    end
  end
end
