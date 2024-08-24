require './test/test_helper'

class GlobalTest < ActiveSupport::TestCase
  let(:cache){ ActiveSupport::Cache::MemoryStore.new }
  let(:values){ {
    array:      [nil, 0],
    hash:       { a: 1 },
    boolean:    false,
    integer:    2,
    float:      3.3,
    bigdecimal: 4.4.to_d,
    date:       Date.new(2000, 1, 1),
    time:       Time.new(2000, 1, 1, 1, 1, 1, 5.hours),
    datetime:   DateTime.new(2000, 1, 1, 1, 1, 1),
    duration:   5.5.days,
    string:     'test',
    nil:        nil,
    symbol:     :test,
    serialized: Setting,
  } }
  let(:multi_values){ {
    [:key, 0].join(GlobalKey::SEPARATOR) => 'key 0',
    [:key, 1].join(GlobalKey::SEPARATOR) => 'key 1',
  } }
  let(:multi_unknowns){ [
    [:key, 2].join(GlobalKey::SEPARATOR),
    [:key, 3].join(GlobalKey::SEPARATOR)
  ] }
  let(:multi_keys){ multi_values.keys + multi_unknowns }

  test '#write, #read, #fetch, #delete, #exist?, #clear, #clear!' do
    values.each do |name, value|
      cache.write(name, value)
      Global.write(name, value)
      result = Global.read(name)
      assert_equal value, result
      assert_equal cache.read(name), result
      if name.in? %i(symbol serialized)
        assert_equal Marshal.dump(value), Marshal.dump(result)
      end
    end

    assert_equal cache.fetch(:new_nil){ nil }, Global.fetch(:new_nil){ nil }
    assert_equal cache.fetch(:new){ :unknown }, Global.fetch(:new){ :unknown }

    Global.delete(:unknown)
    assert_equal false, Global.exist?(:unknown)

    Global.write(:non_expirable, true, expires: false)
    Global.clear
    assert_equal 1, Global.count

    Global.clear!
    assert_equal 0, Global.count
  end

  test '#write_multi, #read_multi, #fetch_multi, #delete_matched' do
    cache.write_multi(multi_values)
    Global.write_multi(multi_values)
    assert_equal cache.read_multi(*multi_values.keys), Global.read_multi(*multi_values.keys)

    assert_equal cache.fetch_multi(*multi_keys){ :unknown }, Global.fetch_multi(*multi_keys){ :unknown }

    assert_equal multi_keys.size, Global.delete_matched("key#{GlobalKey::SEPARATOR}")

    assert_equal false, Global.exist?([:key, 0])
  end

  test '#increment, #decrement' do
    cache.write(:key, 0)
    assert_equal cache.increment(:key), Global.increment(:key)
    assert_equal 2, Global.increment(:key)

    cache.write(:key, 2)
    assert_equal cache.decrement(:key), Global.decrement(:key)
    assert_equal 0, Global.decrement(:key)
  end

  test '#expirable' do
    MixGlobal.with do |config|
      config.expires_in = 16.seconds
      config.touch_in = 8.seconds

      record = Global.write_record(:key, 'value', expires_in: 10.second)
      assert_equal true, record.expires?
      travel_to 9.seconds.from_now do
        assert_equal true, record.expired_touch?
        record = Global.read_record(:key)
        assert_equal Time.current, record.updated_at
        assert_equal false, record.expired_touch?
        assert_equal false, record.expired?
        assert_equal true, record.ongoing?
        assert_equal 1, record.expires_in
        assert_equal 'value', record.data
      end
      travel_to 11.seconds.from_now do
        assert_equal true, record.expired?
        assert_nil Global.read(:key)
      end

      record = Global.write_record(:key, 'value')
      assert_equal true, record.expires?
      travel_to 15.seconds.from_now do
        assert_equal true, record.expired_touch?
        record = Global.read_record(:key)
        assert_equal Time.current, record.updated_at
        assert_equal false, record.expired_touch?
        assert_equal false, record.expired?
        assert_equal true, record.ongoing?
        assert_equal 16, record.expires_in
        assert_equal 'value', record.data
      end
      travel_to 32.seconds.from_now do
        assert_equal true, record.expired?
        assert_nil Global.read(:key)
      end
    end
  end
end
