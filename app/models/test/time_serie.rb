module Test
  class TimeSerie < ApplicationRecord
    has_partition column: :created_at, size: :week

    enum! type: {
      'Test::TimeSeries::DataPoint' => 1,
    }

    attr_readonly :created_at, :type
  end
end
