module Admin
  module Fields
    class DecimalArray < Decimal
      prepend Field::AsArray
    end
  end
end
