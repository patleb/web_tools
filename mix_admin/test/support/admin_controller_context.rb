Admin::Model.class_eval do
  class << self
    alias_method :old_allowed?, :allowed?
    def allowed?(...)
      $test.try(:model_denied) ? false : old_allowed?(...)
    end
  end

  alias_method :old_allowed?, :allowed?
  def allowed?(...)
    $test.try(:presenter_denied) ? false : old_allowed?(...)
  end
end

module AdminControllerContext
  extend ActiveSupport::Concern

  included do
    fixtures :users
    fixtures 'test/records', 'test/related_records'

    let(:current_user){ users(:admin) }
    let(:model_name){ Test::Extensions::RecordExtension.name.to_admin_param }
    let(:model_denied){ false }
    let(:presenter_denied){ false }

    delegate :root_path, to: :controller
  end

  private

  def assert_selects(*selectors)
    selectors.each do |selector|
      assert_select(selector)
    end
  end

  def assert_layout(type, action_name, path: nil, bulk: false)
    if type == :member || action_name == :new
      assert_equal [type, self[:@presenter]], [controller.action_type, controller.action_object]
      assert_equal [self[:@presenter]], self[:@presenters]
      assert_equal "http://127.0.0.1:3333/model/#{model_name}#{path}", self[:@presenter].allowed_url
      assert_equal 'Record extension | Web Tools', self[:@meta][:title]
    else
      assert_equal [type, self[:@model]], [controller.action_type, controller.action_object]
      assert_equal "http://127.0.0.1:3333/model/#{model_name}#{path}", self[:@model].allowed_url
      assert_equal 'Record extensions | Web Tools', self[:@meta][:title]
    end
    assert_equal '/model/user', self[:@meta][:root]
    assert_equal 'Web Tools', self[:@meta][:app]
    assert_selects(
      '.js_scroll_menu',
      ".js_model[data-name=#{self[:@model].to_param}]",
      ".js_action[data-name=#{action_name}]"
    )
    assert_select 'body.admin_layout.lib_layout'
    assert_select "body.admin_#{action_name}_template"
    Admin::Action.all("#{type}?").select(&:navigable?).each do |action|
      assert_select ".nav_actions .#{action.css_class}"
    end
    assert_select '.nav_actions .index_action'
    assert_select ".nav_actions .tab-active .#{action_name}_action" unless bulk
    assert_select ".sidebar li.bordered a[href='http://127.0.0.1:3333/model/#{model_name}']"
  end

  def assert_group(label)
    groups = self[:@section].groups
    group = groups.first
    assert_equal [:default, :virtual], groups.map(&:name)
    assert_equal 'default_group', group.css_class
    assert_equal label, group.label
    assert_nil group.help
    groups.flat_map(&:fields).select(&:label).each do |field|
      assert_select "[href='##{field.name}_field'][data-turbolinks-history=false]"
    end
    yield group
  end
end
