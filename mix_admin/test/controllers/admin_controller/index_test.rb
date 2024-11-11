require './test/test_helper'
require './mix_admin/test/support/admin_controller_context'

class AdminController::IndexTest < ActionDispatch::IntegrationTest
  include AdminControllerContext

  test 'GET :index' do
    assert_equal '/model/:model_name', MixAdmin.routes[:index]
    assert_equal "/model/#{model_name}", MixAdmin::Routes.index_path(model_name: model_name)

    get "/model/#{model_name}", params: { q: '{id}!=_null', f: 'all', s: 'id', r: 'true' }

    assert_response :ok
    assert_layout :collection, :index
    section, presenters = self[:@section], self[:@presenters]
    id, *fields = section.fields.map{ |f| f.with(presenter: presenters.first) }
    assert_equal 2, section.column_name_counts[:id]
    assert_equal 5, presenters.size
    assert_selects(
      '.js_scroll_menu',
      '.js_bulk_form',
      '.js_bulk_checkboxes', '.js_bulk_toggles',  '.js_bulk_buttons',
      '.js_table_head',      '.js_table_body',
      '.js_query_bar',       '.js_search',
      '.js_query_datetime',  '.js_query_keyword', '.js_query_operator', '.js_query_or', '.js_query_and', '.js_query_field',
    )
    assert_equal({ q: '{id}!=_null', f: 'all', s: 'id', r: 'true' }, controller.search_params)
    section.filters.each do |filter|
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
    assert_select ".bulk_menu li button[formaction='http://127.0.0.1:3333/model/#{model_name}/_bulk/delete']"
  end

  test '@model.search' do
    get "/model/#{model_name}"
    name = 'test_related_records.name'
    now = Time.current
    yesterday = 1.day.ago.strftime('%Y-%m-%dT%H:%M:%S')
    tomorrow = 1.day.from_now.strftime('%Y-%m-%dT%H:%M:%S')
    uuid = SecureRandom.uuid
    assert_equal [true, "(string ILIKE '%test%') OR (text ILIKE '%test%') OR (#{name} ILIKE '%test%')"], search_statements('test')
    assert_equal [true, "(string ILIKE 'te%') OR (text ILIKE 'te%') OR (#{name} ILIKE 'te%')",
                        "(string ILIKE '%st') OR (text ILIKE '%st') OR (#{name} ILIKE '%st')"], search_statements('^te st$')
    assert_equal [true, "(string ILIKE 'test string') OR (text ILIKE 'test string') OR (#{name} ILIKE 'test string')"], search_statements('"^test string$"')
    assert_equal [true, "(string ILIKE 'test') OR (text ILIKE 'test')"],               search_statements('{string|text}=^test$')
    assert_equal [true, "(string ILIKE 'te%') OR (string ILIKE '%st')"],               search_statements('{string}=^te|==st$')
    assert_equal [true, "(string NOT ILIKE 'te%') OR (string NOT ILIKE '%st')"],       search_statements('{string}!^te|!=st$')
    assert_equal [true, "string IN ('test','string')"],                                search_statements('{string}=test,string')
    assert_equal [true, "string NOT IN ('test','string')"],                            search_statements('{string}!test,string')
    assert_equal [true, "integer = 4"],                                                search_statements('{integer}four')
    assert_equal [true, "integer >= 0", "integer <= 5"],                               search_statements('{integer}>=zero {integer}<=five')
    assert_equal [true, "integer > 2", "integer < 5"],                                 search_statements('{integer}>two {_}<five')
    assert_equal [true, "decimal > 2", "(test_records.id < 5) OR (decimal < 5) OR (test_related_records.id < 5)"], search_statements('{decimal}>2 <5')
    assert_equal [true, "decimal > 0.0", "decimal < 10.0"],                            search_statements('{decimal}>0.0 {decimal}<10.0')
    assert_equal [true, "string ILIKE '%test%'"],                                      search_statements("{#{model_name}.string}test")
    assert_equal [false],                                                              search_statements("{#{model_name}.unknown}test")
    assert_equal [false],                                                              search_statements('{unknown.string}test')
    assert_equal [true, "(string ILIKE '') OR (text ILIKE '') OR (#{name} ILIKE '')"], search_statements('=^$')
    assert_equal [false],                                                              search_statements('=')
    assert_equal [false],                                                              search_statements('{string}=')
    assert_equal [false],                                                              search_statements('{string}=,')
    assert_equal [false],                                                              search_statements('{id}<1,2')
    assert_equal [false],                                                              search_statements('{id}=_null')
    assert_equal [false],                                                              search_statements('{string}=_null') # required
    assert_equal [true, "text IS NULL"],                                               search_statements('{text}=_null')
    assert_equal [true, "text IS NOT NULL"],                                           search_statements('{text}!_null')
    assert_equal [true, "boolean = TRUE"],                                             search_statements('=_true')
    assert_equal [true, "boolean IS NULL OR boolean = FALSE"],                         search_statements('=_false')
    assert_equal [true, "boolean != FALSE"],                                           search_statements('!_false')
    assert_equal [true, "boolean IS NULL OR boolean != TRUE"],                         search_statements('!_true')
    assert_equal [true, "boolean = TRUE", "boolean IS NULL OR boolean = FALSE"],       search_statements('=_true {_}=_false')
    assert_equal [true, "date BETWEEN '#{now.beginning_of_day.to_fs(:db)}' AND '#{now.end_of_day.to_fs(:db)}.999999'"],              search_statements('{date}=_today')
    assert_equal [true, "date NOT BETWEEN '#{1.hour.ago.beginning_of_hour.to_fs(:db)}' AND '#{now.end_of_hour.to_fs(:db)}.999999'"], search_statements('{date}!_past_hour')
    assert_equal [true, "date NOT BETWEEN '#{1.day.ago.beginning_of_day.to_fs(:db)}' AND '#{now.end_of_hour.to_fs(:db)}.999999'"],   search_statements('{date}!_past_day')
    assert_equal [true, "(datetime < '#{yesterday.sub('T', ' ')}') OR (datetime > '#{tomorrow.sub('T', ' ')}')"],                    search_statements("{datetime}<#{yesterday}|>#{tomorrow}")
    assert_equal [true, "uuid = '#{uuid}'"],                                           search_statements("=#{uuid}")
    assert_equal [false],                                                              search_statements('{string}=<script></script>')
    assert_equal [true, "#{name} ILIKE '%related to 1%'"],                             search_statements("{test-related_record.name}=related\\ to\\ 1")
    assert_equal [true, "(string ILIKE '%to%') OR (#{name} ILIKE '%to%')"],            search_statements('{test-related_record.name|string}=to')
    assert_equal [true, "#{name} ILIKE '%1%'"],                                        search_statements("{test-related_record.name}='1'")
    assert_equal [true, "#{name} ILIKE '%related%'"],                                  search_statements('{name}related')
  end

  private

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
