module Admin
  module Fields
    class TimestampArray < Timestamp
      prepend Field::AsArray
      prepend Field::AsRange
    end
  end
end
