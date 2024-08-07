require './test/test_helper'

class ActiveRecord::Base::WithPartitionTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  let(:keys){ (1..22).to_a }
  let(:dates){ keys.map{ |i| i.days.from_now } }
  let(:count){ keys.size }

  after do
    Test::MuchRecord._drop_all_partitions!
    Test::TimeSeries::DataPoint._drop_all_partitions!
  end

  test '.has_partition' do
    Test::MuchRecord.insert_all! keys.map{ |i| { name: "Name #{i}" } }
    assert_equal count, Test::MuchRecord.count
    assert_equal (count / Test::MuchRecord.partition_size + 1), Test::MuchRecord.partitions.size
    assert_equal false, Test::MuchRecord.partition_empty?('test_much_records_0000000000000000015')

    Test::TimeSeries::DataPoint.insert_all! dates.map.with_index{ |date, i| { created_at: date, json_data: { name: "Day #{i}" } } }
    assert_equal count, Test::TimeSeries::DataPoint.count
    assert_equal 4, Test::TimeSeries::DataPoint.partitions.size
  end

  test '.partition_bucket' do
    assert_equal 15, ActiveRecord::Base.partition_bucket('test_much_records_0000000000000000015')
    assert_equal Time.utc(2024, 7, 15), ActiveRecord::Base.partition_bucket('test_time_series_2024_07_15')
  end
end
