require './test/test_helper'

class ActiveRecord::Relation::WithJsonAttributeTest < ActiveSupport::TestCase
  fixtures 'test/records'

  test '.select, .where, .order, .group' do
    assert_equal 'j_string-1', Test::Record.select(:j_string).where(j_integer: nil).take.j_string
    assert_equal [1],    ids_for(j_integer: nil)
    assert_equal [2, 3], ids_for(j_integer: [2, 3])
    assert_equal [5, 4], ids_for(j_integer: 4..5, order: { j_integer: :desc })
    assert_equal [4],    ids_for(j_integer: 4...5)
    assert_equal [5],    ids_for(j_integer: 5)
    assert_equal [5],    ids_for(j_integer: ['>', 4])
    assert_equal [5],    ids_for(j_string: ['~', '^j_str.*[^1-4]$'])
    assert_equal [5],    ids_for(j_string: ['LIKE', 'j_str%5'])
    assert_equal [4, 2], ids_for(j_boolean: false, order: { j_string: :desc })
    assert_equal [0, 1], Test::Record.select('MAX(boolean::INT) AS int', :j_boolean).group(:j_boolean).order(:int).map(&:int)
  end

  test '.where_not' do
    assert_equal [2, 3, 4, 5], ids_for(_not: true, j_integer: nil)
    assert_equal [4, 5],       ids_for(_not: true, j_integer: [2, 3])
    assert_equal [2, 3, 5],    ids_for(_not: true, j_integer: 4...5)
    assert_equal [2, 3, 4],    ids_for(_not: true, j_integer: 5)
    assert_equal [2, 4],       ids_for(_not: true, j_integer: ['>', 4], id: 3)
    assert_equal [1, 2, 3, 4], ids_for(_not: true, j_string: ['~', '^j_str.*[^1-4]$'])
    assert_equal [1, 2, 3, 4], ids_for(_not: true, j_string: ['LIKE', 'j_str%5'])
  end

  test '.calculate_from' do
    assert_equal 2.5, Test::Record.calculate_from(:average, Test::Record.group(:j_boolean), :count, :id)
    assert_equal 2.0, Test::Record.calculate_from(:count, Test::Record.group(:j_boolean).distinct, :count, :j_boolean)
    assert_equal 1.0, Test::Record.calculate_from(:count, Test::Record.group(:j_boolean).distinct, :count, :j_boolean, distinct: true)
  end

  test '.calculate_multi' do
    cols = %i(percentile median stddev variance)
    args = [[:percentile, :j_decimal, 0.8], [:median, :j_decimal], [:stddev, :j_decimal], [:variance, :j_decimal]]
    values = cols.zip(Test::Record.calculate_multi(args).first).to_h
    assert_equal      4.62,  values[:percentile]
    assert_equal      3.3,   values[:median]
    assert_in_epsilon 1.739, values[:stddev]
    assert_equal      3.025, values[:variance]
    values = cols.zip(Test::Record.group(:j_boolean).calculate_multi(args)[true]).to_h
    assert_equal 4.62, values[:percentile]
    assert_equal 3.3,  values[:median]
    assert_equal 2.2,  values[:stddev]
    assert_equal 4.84, values[:variance]
  end

  test '.pluck' do
    assert_equal [[2, false], [4, false]], Test::Record.where(j_boolean: false).pluck(:id, :j_boolean).sort
  end

  private

  def ids_for(_not: false, order: nil, **conditions)
    scope = _not ? Test::Record.where_not(conditions) : Test::Record.where(conditions)
    order ? scope.order(**order).pluck(:id) : scope.pluck(:id).sort
  end
end
