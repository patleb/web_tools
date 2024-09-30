require './test/test_helper'
require './mix_admin/test/support/admin_controller_context'

class AdminController::NewTest < ActionDispatch::IntegrationTest
  include AdminControllerContext

  context '#new' do
    test 'render :new as GET' do
      assert_equal '/model/:model_name/new', MixAdmin.routes[:new]
      assert_equal "/model/#{model_name}/new", MixAdmin::Routes.new_path(model_name: model_name)

      get "/model/#{model_name}/new"

      groups = self[:@section].groups
      group = groups.first
      string_field = group.fields.find{ |f| f.name == :string }
      assert_nil group.fields.find{ |f| f.name == :id }
      assert_response :ok
      assert_equal [:collection, self[:@presenter]], [controller.action_type, controller.action_object]
      assert_equal [:default, :virtual], groups.map(&:name)
      assert_equal 'default_group', group.css_class
      assert_equal 'Nouveau(elle) Record extension', group.label
      assert_nil group.help
      assert_equal 'string_field string_type', string_field.css_class
      assert_equal 'String', string_field.label
      assert_equal '-', string_field.pretty_value
      assert_equal "<input type='text' name='string' class='input input-bordered' required='required' id='string'></input>",
        string_field.pretty_input.gsub("\"", "'")
      assert_equal [self[:@presenter]], self[:@presenters]
      assert_equal "http://127.0.0.1:3333/model/#{model_name}/new", self[:@presenter].allowed_url
      assert_equal '/model/user', self[:@meta][:root]
      assert_equal 'Record extension | Web Tools', self[:@meta][:title]
      assert_equal 'Web Tools', self[:@meta][:app]
      assert_selects '.js_scroll_menu', '.js_model'
      assert_select 'body.admin_layout'
      assert_select 'body.admin_new_template'
      Admin::Action.all(:collection?).select(&:navigable?).each do |action|
        assert_select ".nav_actions .#{action.css_class}"
      end
      assert_select '.nav_actions .index_action'
      assert_select '.nav_actions .tab-active .new_action'
      groups.flat_map(&:fields).select(&:label).each do |field|
        assert_select "[href='##{field.name}_field'][data-turbolinks-history=false]"
      end
      assert_select ".sidebar li.bordered a[href='http://127.0.0.1:3333/model/#{model_name}']"
    end

    test 'render :new as POST' do
      post "/model/#{model_name}/new", params: { model_name.underscore => { string: 'new-string' } }

      assert Test::Extensions::RecordExtension.find_by(string: 'new-string')
    end
  end
end
