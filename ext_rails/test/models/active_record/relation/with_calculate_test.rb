require './test/test_helper'

class ActiveRecord::Relation::WithCalculateTest < ActiveSupport::TestCase
  fixtures 'test/records'

  test '.stddev' do
    assert_in_epsilon 1.739, Test::Record.stddev(:decimal)
  end

  test '.variance' do
    assert_in_epsilon 3.025, Test::Record.variance(:decimal)
  end

  test '.median' do
    assert_equal 3.3, Test::Record.median(:decimal)
  end

  test '.percentile' do
    assert_equal 4.62, Test::Record.percentile(:decimal, 0.8)
  end

  test '.count_estimate, .invert_where' do
    assert Test::Record.odd.count_estimate >= 1
    assert_equal 0, Test::Record.none.count_estimate
  end

  test '.group_by_period' do
    { minute_of_hour: {5=>1, 6=>1, 7=>1, 8=>1, 9=>1},
      hour_of_day:    {4=>1, 5=>1, 6=>1, 7=>1, 8=>1},
      day_of_week:    {3=>2, 4=>1, 6=>2},
      day_of_month:   {3=>1, 4=>1, 5=>1, 6=>1, 7=>1},
      day_of_year:    {34=>1, 64=>1, 96=>1, 127=>1, 159=>1},
      month_of_year:  {2=>1, 3=>1, 4=>1, 5=>1, 6=>1},
      week:           {Time.utc(2000,1,31)=>1, Time.utc(2000,2,28)=>1, Time.utc(2000,4,3)=>1, Time.utc(2000,5,1)=>1, Time.utc(2000,6,5)=>1},
      day:            {Time.utc(2000,2,3)=>1, Time.utc(2000,3,4)=>1, Time.utc(2000,4,5)=>1, Time.utc(2000,5,6)=>1, Time.utc(2000,6,7)=>1},
      month:          {Time.utc(2000,2,1)=>1, Time.utc(2000,3,1)=>1, Time.utc(2000,4,1)=>1, Time.utc(2000,5,1)=>1, Time.utc(2000,6,1)=>1},
      quarter:        {Time.utc(2000,1,1)=>2, Time.utc(2000,4,1)=>3},
      year:           {Time.utc(2000,1,1)=>5},
      minute:         {Time.utc(2000,2,3,4,5)=>1, Time.utc(2000,3,4,5,6)=>1, Time.utc(2000,4,5,6,7)=>1, Time.utc(2000,5,6,7,8)=>1, Time.utc(2000,6,7,8,9)=>1},
      hour:           {Time.utc(2000,2,3,4)=>1, Time.utc(2000,3,4,5)=>1, Time.utc(2000,4,5,6)=>1, Time.utc(2000,5,6,7)=>1, Time.utc(2000,6,7,8)=>1},
    }.each do |period, value|
      assert_equal value, Test::Record.group_by_period(period, column: :datetime).count
    end
    assert_equal(
      {Time.utc(2000,2,3)=>1, Time.utc(2000,3,4)=>1, Time.utc(2000,4,5)=>1, Time.utc(2000,5,6)=>1, Time.utc(2000,6,7)=>1},
      Test::Record.group_by_period(1.day, column: :datetime).count
    )
    assert_equal(
      {Time.utc(2000,2,3)=>1},
      Test::Record.group_by_period(:day, column: :datetime, time_range: Time.utc(2000,1,1)..Time.utc(2000,3,1)).count
    )
  end

  test '.top_group_calculate' do
    assert_equal [true, 3], Test::Record.top_group_calculate(:boolean, :count).first
    assert_equal 1, Test::Record.top_group_calculate(:boolean, :id, :count)[[true, 5]]
    assert_equal [true, 4.62], Test::Record.top_group_calculate(:boolean, :percentile, column: :decimal, arg: 0.8).first
  end

  test '.calculate_from' do
    assert_equal 2.0, Test::Record.calculate_from(:average, Test::Record.even, :count, :id)
    assert_equal 2.5, Test::Record.calculate_from(:average, Test::Record.group(:boolean), :count, :id)
    assert_equal 2.0, Test::Record.calculate_from(:count, Test::Record.group(:boolean).distinct, :count, :boolean)
    assert_equal 1.0, Test::Record.calculate_from(:count, Test::Record.group(:boolean).distinct, :count, :boolean, distinct: true)
    assert_equal 4.62, Test::Record.calculate_from(:average, Test::Record.all, :percentile, :decimal, 0.8)
    assert_equal 4.62, Test::Record.calculate_from(:percentile, Test::Record.group(:id), :average, :decimal, arg: 0.8)
  end

  test '.calculate_multi' do
    cols = %i(percentile median stddev variance)
    args = [[:percentile, :decimal, 0.8], [:median, :decimal], [:stddev, :decimal], [:variance, :decimal]]
    values = cols.zip(Test::Record.calculate_multi(args).first).to_h
    assert_equal      4.62,  values[:percentile]
    assert_equal      3.3,   values[:median]
    assert_in_epsilon 1.739, values[:stddev]
    assert_equal      3.025, values[:variance]
    values = cols.zip(Test::Record.group(:boolean).calculate_multi(args)[true]).to_h
    assert_equal 4.62, values[:percentile]
    assert_equal 3.3,  values[:median]
    assert_equal 2.2,  values[:stddev]
    assert_equal 4.84, values[:variance]
  end
end
