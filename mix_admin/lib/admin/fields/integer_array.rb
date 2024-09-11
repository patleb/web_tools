module Admin
  module Fields
    class IntegerArray < Integer
      prepend Field::AsArray
      prepend Field::AsRange
    end
  end
end
