module Test
  class TimeSerie < ApplicationRecord
    enum! type: {
      'Test::TimeSeries::DataPoint' => 1,
    }

    attr_readonly :created_at, :type
  end
end
