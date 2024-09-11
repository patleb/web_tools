module Admin
  module Fields
    class TimeArray < Time
      prepend Field::AsArray
      prepend Field::AsRange
    end
  end
end
