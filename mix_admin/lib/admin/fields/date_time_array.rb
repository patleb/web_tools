module Admin
  module Fields
    class DateTimeArray < DateTime
      prepend Field::AsArray
      prepend Field::AsRange
    end
  end
end
