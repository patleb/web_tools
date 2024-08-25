require './test/test_helper'

class VirtualRecordTest < ActiveSupport::TestCase
  let(:values) do
    Test::VirtualRecord.list.map do |r|
      r[:date] = r[:id].days.from_now.to_date
      r[:odd] = r[:id].odd?
      r[:name] = nil if r[:name].blank?
      r[:type] = :simple
      r
    end
  end
  let(:even){ values.select{ |r| r[:id].even? } }
  let(:sorted){ values.sort_by{ |r| v = r[:name]; [v ? 0 : 1, v] }.reverse }
  let(:paginated){ values[6, 6] }

  around do |test|
    travel_to Time.utc(2000, 1, 1, 1, 1, 1) do
      test.call
    end
  end

  test '.all' do
    assert_equal values, Test::VirtualRecord.all.map(&:attributes_hash)
  end

  test '.find' do
    assert_equal(resource(5), Test::VirtualRecord.find(5).attributes_hash)
  end

  test '.scope' do
    assert_equal even, Test::VirtualRecord.even.map(&:attributes_hash)
  end

  test '.order and .reverse_order' do
    assert_equal sorted, Test::VirtualRecord.order(:name).reverse_order.map(&:attributes_hash)
  end

  test '.limit and .offset' do
    assert_equal paginated, Test::VirtualRecord.limit(10).offset(6).map(&:attributes_hash)
  end

  test '.where' do
    assert_equal(resource(5),               Test::VirtualRecord.where(id: 5, name: 'Name 5').take.attributes_hash)
    assert_equal(resources(1, 2),           resources_for([id: [1, 2]]))
    assert_equal(resources(-1),             resources_for([name: nil]))
    assert_equal(resources(-1),             resources_for(['name IS NULL'])) # blank
    assert_equal(resources(0, 1),           resources_for(['id >= ?', 0], ['id <= ?', 1]))
    assert_equal(resources(1),              resources_for(['name = ?', 'Name 1']))
    assert_equal(resources(1, 10),          resources_for(['name ILIKE ?', 1]))
    assert_equal(values.size - 2,           resources_for(['name NOT ILIKE ?', 1]).size)
    assert_equal(resources(2, 3),           resources_for(['(name ILIKE ?) OR (name ILIKE ?)', 'Name 2', 'Name 3']))
    assert_equal(resources(*0.step(10, 2)), resources_for(['odd IS NULL OR odd = ?', false]))
    assert_equal(resources(*0.step(10, 2)), resources_for(['odd IS NULL OR odd != ?', true]))
    assert_equal(resources(1, 2),           resources_for(['id IN (?,?)', 1, 2]))
    assert_equal(resources(1, 2),           resources_for(['date BETWEEN ? AND ?', '2000-01-02', Time.utc(2000, 1, 3)]))
  end

  private

  def resources_for(*sqls)
    sqls.reduce(Test::VirtualRecord){ |scope, (sql, *values)| scope.where(sql, *values) }.map(&:attributes_hash)
  end

  def resources(*ids)
    ids.map{ |id| resource(id) }
  end

  def resource(id)
    values.find{ |r| r[:id] == id }
  end
end
