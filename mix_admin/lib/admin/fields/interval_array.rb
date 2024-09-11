module Admin
  module Fields
    class IntervalArray < Interval
      prepend Field::AsArray
    end
  end
end
