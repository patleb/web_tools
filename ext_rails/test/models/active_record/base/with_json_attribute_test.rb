require './test/rails_helper'

class ActiveRecord::Base::WithJsonAttributeTest < ActiveSupport::TestCase
  fixtures 'test/records'

  test '.json_attribute?, .json_attribute, .json_translate' do
    assert_equal true, Test::Record.json_attribute?(:name)
    record = Test::Record.find(1)

    assert_equal 'Name', record.name
    record.update! name: 'New Name'
    assert_equal({ name: 'New Name' }, record.json_data)

    assert_equal "Info for 'New Name'", record.info

    record.update! name: ''
    assert_nil record.name
    assert_equal({}, record.json_data)

    now = Time.current
    record.update! j_datetime: now
    record.reload
    assert_in_delta now, record.j_datetime, 1

    record.update! json_data: { j_text: 'New Text', unknown: 'Ignored' }
    assert_equal 'New Text', record.j_text
    assert_equal({ j_text: 'New Text' }, record.json_data)

    assert_equal 'Titre', record.title
    assert_equal 'Title', record.title(:en)
    record.update! title_fr: 'Nouveau Titre'
    assert_equal 'Nouveau Titre', record.title
    assert_equal 'Nouveau Titre', record.title(:en)
    record.update! title_en: 'New Title'
    assert_equal 'Nouveau Titre', record.title
    assert_equal 'New Title', record.title(:en)

    assert record.json_data.is_a?(ActiveSupport::HashWithIndifferentAccess)
  end

  test '.json_key' do
    column = '"test_records"."json_data"'
    assert_equal "(#{column}->>'name')::TEXT", Test::Record.json_key(:name)
    assert_equal "(#{column}->>'name')::DATE", Test::Record.json_key(:name, cast: 'date')
    assert_equal "(#{column}->>'j_date')::DATE AS date", Test::Record.json_key(:j_date, as: 'date')
    assert_equal "(#{column}#>>'{j_json,name}')::TEXT", Test::Record.json_key(:j_json, :name)
    assert_equal "(#{column}#>>'{j_json,time}')::TEXT AS j_json_time", Test::Record.json_key(:j_json, :time, as: true)
    assert_equal "(#{column}#>>'{j_json,time}')::TIME", Test::Record.json_key(:j_json, :time, cast: 'time')
  end
end
