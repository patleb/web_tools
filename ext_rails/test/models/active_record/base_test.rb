require './test/test_helper'

class ActiveRecord::BaseTest < ActiveSupport::TestCase
  fixtures 'test/records', 'test/related_records'

  let(:run_timeout){ 2 }
  let(:record){ Test::Record.find(1) }

  test '.with_timezone' do
    time = Time.current
    assert_equal 'UTC', time.time_zone.name
    record.datetime = time
    ActiveRecord::Base.with_timezone('America/New_York') do
      assert_equal false, ActiveRecord::Base.time_zone_aware_attributes
      assert_equal 'America/New_York', record.datetime.time_zone.name
    end
  end

  test '#slice, #except, #attributes_hash' do
    assert_equal({ id: 1, name: 'Name' }, record.slice(:id, :name))
    assert_equal({ id: 1, name: 'Name' }, record.except(*record.attributes_hash.keys.except(:id, :name)))
  end

  test '#can_destroy?' do
    assert_equal false, record.can_destroy?
  end

  test '#locking_enabled?' do
    record = Test::RelatedRecord.find(1)
    lock_was = record.lock_version
    record.touch
    assert_equal lock_was, record.lock_version
  end

  test '.scope' do
    Test::Record.class_eval do
      scope 'Invalid Name', -> { raise 'should not be called' }
    end
    assert_equal false, Test::Record.respond_to?('Invalid Name')
  end

  test '.with_timeout' do
    assert_raises ActiveRecord::QueryCanceled do
      ActiveRecord::Base.with_timeout 1 do
        ActiveRecord::Base.connection.select_value 'SELECT pg_sleep(2)'
      end
    end
  end

  test '.encoding' do
    assert_equal 'UTF-8', ActiveRecord::Base.encoding.name
  end

  test '.sanitize_matcher' do
    assert_equal 'test:record%', Test::Record.sanitize_matcher(/^test:record/)
    assert_equal '%test:record', Test::Record.sanitize_matcher(/test:record$/)
    assert_equal 'test:related\\_record', Test::Record.sanitize_matcher(/^test:related_record$/)
    assert_equal 'test:related/record', Test::Record.sanitize_matcher(/^test:related\/record$/)
    assert_equal 'test:related%record', Test::Record.sanitize_matcher(/^test:related.*record$/)
    assert_equal 'test:related_record', Test::Record.sanitize_matcher(/^test:related.record$/)
  end

  test '.quote_column' do
    assert_equal '"table"."column"', Test::Record.quote_column('table.column')
    assert_equal '"table"."column"::BIGINT', Test::Record.quote_column('table.column::BIGINT')
    assert_equal '"test_records"."column"::BIGINT', Test::Record.quote_column('column::BIGINT')
    assert_equal '"test_records"."column"', Test::Record.quote_column(:column)
  end

  test '.viable_models, .sti_parents, .polymorphic_parents, .sti?, .inherited_types, .enum!' do
    assert_includes ActiveRecord::Base.viable_models, 'Test::RelatedRecord'
    assert_includes ActiveRecord::Base.sti_parents, 'Test::TimeSerie'
    assert_equal 'Test::RelatedRecord', ActiveRecord::Base.polymorphic_parents.dig('Test::MuchRecord', :relatable, 0).name
  end
end
