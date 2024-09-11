require './test/test_helper'

Admin::Model.class_eval do
  class << self
    alias_method :old_allowed?, :allowed?
    def allowed?(...)
      $test.model_denied ? false : old_allowed?(...)
    end
  end

  alias_method :old_allowed?, :allowed?
  def allowed?(...)
    $test.presenter_denied ? false : old_allowed?(...)
  end
end

class AdminControllerTest < ActionDispatch::IntegrationTest
  fixtures 'test/records'

  let(:model_name){ 'test-extensions-record_extension' }
  let(:model_denied){ false }
  let(:presenter_denied){ false }

  around do |test|
    MixAdmin.with do |config|
      config.record_label_methods = []
      test.call
    end
  end

  it 'should return :not_found on empty :model_name' do
    get '/admin//show/1'
    assert_response :not_found
  end

  it 'should return :not_found on unknown model' do
    get '/model/unknown/show/1'
    assert_response :not_found
  end

  it 'should return :not_found on bad id' do
    get "/model/#{model_name}/-1"
    assert_response :not_found
  end

  describe 'denied model' do
    let(:model_denied){ true }

    it 'should return :not_found on denied model' do
      get "/model/#{model_name}/1"
      assert_response :not_found
    end
  end

  describe 'denied presenter' do
    let(:presenter_denied){ true }

    it 'should return :not_found on denied presenter' do
      get "/model/#{model_name}/1"
      assert_response :not_found
    end
  end

  describe '#show' do
    it 'should define path helpers' do
      assert_equal '/model/:model_name/:id', MixAdmin.routes[:show]
      assert_equal "/model/#{model_name}/1", MixAdmin::Routes.show_path(model_name: model_name, id: 1)
    end

    test 'render :show' do
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
      assert_equal 'id_field integer_type', id_field.css_class
      assert_equal 'Id', id_field.label
      assert_equal '1', id_field.pretty_value
      assert_equal [self[:@presenter]], self[:@presenters]
      assert_equal "http://127.0.0.1:3333/model/#{model_name}/1", self[:@presenter].allowed_url
      assert_equal 'http://127.0.0.1:3333/model', self[:@meta][:root]
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

  describe '#index' do
    it 'should define path helpers' do
      assert_equal '/model/:model_name', MixAdmin.routes[:index]
      assert_equal "/model/#{model_name}", MixAdmin::Routes.index_path(model_name: model_name)
    end

    test 'render :index' do
      get "/model/#{model_name}", params: { q: '{id}!=_null', f: 'all', s: 'id', r: 'true' }
      presenter = self[:@presenters].first
      id, *fields = self[:@section].fields.map{ |f| f.with(presenter: presenter) }
      assert_response :ok
      assert_equal [:collection, self[:@model]], [controller.action_type, controller.action_object]
      assert_equal 'Record extensions | Web Tools', self[:@meta][:title]
      assert_selects(
        '.js_scroll_menu',
        '.js_bulk_form',
        '.js_bulk_checkboxes', '.js_bulk_toggles',  '.js_bulk_buttons',
        '.js_table_head',      '.js_table_body',
        '.js_search',
        '.js_query_datetime',  '.js_query_keyword', '.js_query_operator', '.js_query_or', '.js_query_and', '.js_query_field',
        ".js_model[data-name=#{self[:@model].to_param}]",
      )
      assert_equal({ q: '{id}!=_null', f: 'all', s: 'id', r: 'true' }, controller.search_params)
      assert_equal 5, self[:@presenters].size
      Admin::Action.all(:collection?).select(&:navigable?).each do |action|
        assert_select ".nav_actions .#{action.css_class}"
      end
      assert_select '.nav_actions .tab-active .index_action'
      self[:@section].filters.each do |filter|
        assert_select ".filter_menu .#{filter}_filter"
      end
      assert_select '.filter_title.active'
      assert_select '.filter_menu .active.all_filter'
      controller.search_params.except(:q).each do |name, value|
        assert_select "input[name=#{name}][value='#{value}'][type=hidden]"
      end
      assert_select "input#q[name=q][value='#{controller.search_params[:q]}'][type=search]"
      assert_select '.model_info p'
      assert_select "input.checkbox[name='ids[]'][value='#{id.value}']"
      assert_select "th.sticky .field_value.#{id.css_class.split.join('.')}"
      assert_select ".inline_menu li a[href='http://127.0.0.1:3333/model/#{model_name}/#{id.value}/delete']"
      fields.each do |field|
        assert_select "td.tooltip .field_value.#{field.css_class.split.join('.')}"
      end
      assert_select ".bulk_menu li button[formaction='http://127.0.0.1:3333/model/#{model_name}/bulk/delete']"
    end

    test '@model.search' do
      get "/model/#{model_name}"
      now = Time.current
      yesterday = 1.day.ago.strftime('%Y-%m-%dT%H:%M:%S')
      tomorrow = 1.day.from_now.strftime('%Y-%m-%dT%H:%M:%S')
      uuid = SecureRandom.uuid
      assert_equal [true, "(string ILIKE '%test%') OR (text ILIKE '%test%')"],           search_statements('test')
      assert_equal [true, "(string ILIKE 'te%') OR (text ILIKE 'te%')", "(string ILIKE '%st') OR (text ILIKE '%st')"],
                                                                                         search_statements('^te st$')
      assert_equal [true, "(string ILIKE 'test string') OR (text ILIKE 'test string')"], search_statements('"^test string$"')
      assert_equal [true, "(string ILIKE 'test') OR (text ILIKE 'test')"],               search_statements('{string|text}=^test$')
      assert_equal [true, "(string ILIKE 'te%') OR (string ILIKE '%st')"],               search_statements('{string}=^te|==st$')
      assert_equal [true, "(string NOT ILIKE 'te%') OR (string NOT ILIKE '%st')"],       search_statements('{string}!^te|!=st$')
      assert_equal [true, "string IN ('test','string')"],                                search_statements('{string}=test,string')
      assert_equal [true, "string NOT IN ('test','string')"],                            search_statements('{string}!test,string')
      assert_equal [true, "integer >= 0", "integer <= 10"],                              search_statements('{integer}>=0 {integer}<=10')
      assert_equal [true, "integer > 2", "integer < 5"],                                 search_statements('{integer}>2 {_}<5')
      assert_equal [true, "decimal > 0.0", "decimal < 10.0"],                            search_statements('{decimal}>0.0 {decimal}<10.0')
      assert_equal [true, "string ILIKE '%test%'"],                                      search_statements("{#{model_name}.string}test")
      assert_equal [false],                                                              search_statements("{#{model_name}.unknown}test")
      assert_equal [false],                                                              search_statements('{unknown.string}test')
      assert_equal [true, "(string ILIKE '') OR (text ILIKE '')"],                       search_statements('=^$')
      assert_equal [false],                                                              search_statements('=')
      assert_equal [false],                                                              search_statements('{string}=')
      assert_equal [false],                                                              search_statements('{string}=,')
      assert_equal [false],                                                              search_statements('{id}<1,2')
      assert_equal [false],                                                              search_statements('{id}=_null')
      assert_equal [true, "string IS NULL"],                                             search_statements('{string}=_null')
      assert_equal [true, "string IS NOT NULL"],                                         search_statements('{string}!_null')
      assert_equal [true, "boolean = TRUE"],                                             search_statements('=_true')
      assert_equal [true, "boolean IS NULL OR boolean = FALSE"],                         search_statements('=_false')
      assert_equal [true, "boolean != FALSE"],                                           search_statements('!_false')
      assert_equal [true, "boolean IS NULL OR boolean != TRUE"],                         search_statements('!_true')
      assert_equal [true, "boolean = TRUE", "boolean IS NULL OR boolean = FALSE"],       search_statements('=_true {_}=_false')
      assert_equal [true, "date BETWEEN '#{now.beginning_of_day.to_fs(:db)}' AND '#{now.end_of_day.to_fs(:db)}.999999'"],
                                                                                         search_statements('{date}=_today')
      assert_equal [true, "date NOT BETWEEN '#{1.hour.ago.beginning_of_hour.to_fs(:db)}' AND '#{now.end_of_hour.to_fs(:db)}.999999'"],
                                                                                         search_statements('{date}!_past_hour')
      assert_equal [true, "date NOT BETWEEN '#{1.day.ago.beginning_of_day.to_fs(:db)}' AND '#{now.end_of_hour.to_fs(:db)}.999999'"],
                                                                                         search_statements('{date}!_past_day')
      assert_equal [true, "(datetime < '#{yesterday.sub('T', ' ')}') OR (datetime > '#{tomorrow.sub('T', ' ')}')"],
                                                                                         search_statements("{datetime}<#{yesterday}|>#{tomorrow}")
      assert_equal [true, "uuid = '#{uuid}'"],                                           search_statements("=#{uuid}")
      assert_equal [false],                                                              search_statements("{string}=<script></script>")
    end
  end

  describe '#export' do

  end

  private

  def assert_selects(*selectors)
    selectors.each do |selector|
      assert_select(selector)
    end
  end

  def search_statements(query)
    model = self[:@model]
    scope = model.search(model.scope, self[:@section], q: query)
    scope = controller.paginator.scope if scope.is_a? Array
    statements = scope.values[:where].send(:predicates).drop(1)
    statements = [] if statements.last == '1=0'
    success = controller.flash[:alert].blank?
    controller.flash.delete(:alert)
    [success].concat(statements)
  end
end
