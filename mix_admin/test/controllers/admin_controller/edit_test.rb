require './test/test_helper'
require './mix_admin/test/support/admin_controller_context'

class AdminController::EditTest < ActionDispatch::IntegrationTest
  include AdminControllerContext

  context '#edit' do
    test 'render :edit as GET' do
      assert_equal '/model/:model_name/:id/edit', MixAdmin.routes[:edit]
      assert_equal "/model/#{model_name}/1/edit", MixAdmin::Routes.edit_path(model_name: model_name, id: 1)

      get "/model/#{model_name}/1/edit"

      groups = self[:@section].groups
      group = groups.first
      id_field = group.fields.find{ |f| f.name == :id }
      assert_response :ok
      assert_equal [:member, self[:@presenter]], [controller.action_type, controller.action_object]
      assert_equal [:default, :virtual], groups.map(&:name)
      assert_equal 'default_group', group.css_class
      assert_equal 'Record extension #1', group.label
      assert_nil group.help
      assert_equal 'id_field integer_type', id_field.css_class
      assert_equal 'Id', id_field.label
      assert_equal '1', id_field.pretty_value
      assert_equal [self[:@presenter]], self[:@presenters]
      assert_equal "http://127.0.0.1:3333/model/#{model_name}/1/edit", self[:@presenter].allowed_url
      assert_equal '/model/user', self[:@meta][:root]
      assert_equal 'Record extension | Web Tools', self[:@meta][:title]
      assert_equal 'Web Tools', self[:@meta][:app]
      assert_selects '.js_scroll_menu', '.js_model'
      assert_select 'body.admin_layout'
      assert_select 'body.admin_edit_template'
      Admin::Action.all(:member?).select(&:navigable?).each do |action|
        assert_select ".nav_actions .#{action.css_class}"
      end
      assert_select '.nav_actions .index_action'
      assert_select '.nav_actions .tab-active .edit_action'
      groups.flat_map(&:fields).select(&:label).each do |field|
        assert_select "[href='##{field.name}_field'][data-turbolinks-history=false]"
      end
      assert_select ".sidebar li.bordered a[href='http://127.0.0.1:3333/model/#{model_name}']"
    end

    test 'render :edit as POST' do
      post "/model/#{model_name}/1/edit", params: { model_name.underscore => { string: 'new-string' } }

      record = Test::Extensions::RecordExtension.find(1)
      assert_equal 'new-string', record.string
    end
  end
end
