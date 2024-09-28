require './test/test_helper'
require './mix_admin/test/support/admin_controller_context'

class AdminController::ShowTest < ActionDispatch::IntegrationTest
  include AdminControllerContext

  context '#show' do
    test 'return :not_found on empty :model_name' do
      get '/admin//show/1'
      assert_response :not_found
    end

    test 'return :not_found on unknown model' do
      get '/model/unknown/show/1'
      assert_response :not_found
    end

    test 'return :not_found on bad id' do
      get "/model/#{model_name}/-1"
      assert_response :not_found
    end

    context 'denied model' do
      let(:model_denied){ true }

      test 'return :not_found on denied model' do
        get "/model/#{model_name}/1"
        assert_response :not_found
      end
    end

    context 'denied presenter' do
      let(:presenter_denied){ true }

      test 'return :not_found on denied presenter' do
        get "/model/#{model_name}/1"
        assert_response :not_found
      end
    end

    test 'render :show' do
      assert_equal '/model/:model_name/:id', MixAdmin.routes[:show]
      assert_equal "/model/#{model_name}/1", MixAdmin::Routes.show_path(model_name: model_name, id: 1)

      get "/model/#{model_name}/1"

      groups = self[:@section].groups
      group = groups.first
      id_field = group.fields.find{ |f| f.name == :id }
      assert_response :ok
      assert_equal [:member, self[:@presenter]], [controller.action_type, controller.action_object]
      assert_equal [:default, :virtual], groups.map(&:name)
      assert_equal 'default_group', group.css_class
      assert_equal 'Record extension #1', group.label
      assert_nil group.help
      assert_equal 'id_field integer_type readonly', id_field.css_class
      assert_equal 'Id', id_field.label
      assert_equal '1', id_field.pretty_value
      assert_equal [self[:@presenter]], self[:@presenters]
      assert_equal "http://127.0.0.1:3333/model/#{model_name}/1", self[:@presenter].allowed_url
      assert_equal '/model/user', self[:@meta][:root]
      assert_equal 'Record extension | Web Tools', self[:@meta][:title]
      assert_equal 'Web Tools', self[:@meta][:app]
      assert_selects '.js_scroll_menu', '.js_model'
      assert_select 'body', class: /admin_layout/
      assert_select 'body', class: /admin_show_template/
      Admin::Action.all(:member?).select(&:navigable?).each do |action|
        assert_select ".nav_actions .#{action.css_class}"
      end
      assert_select '.nav_actions .index_action'
      assert_select '.nav_actions .tab-active .show_action'
      groups.flat_map(&:fields).each do |field|
        assert_select "[href='##{field.name}_field'][data-turbolinks-history=false]"
      end
      assert_select ".sidebar li.bordered a[href='http://127.0.0.1:3333/model/#{model_name}']"
    end
  end
end
