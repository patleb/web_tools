module Admin
  module Fields
    class DateArray < Date
      prepend Field::AsArray
      prepend Field::AsRange
    end
  end
end
