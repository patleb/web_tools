module Admin
  module Field::AsRange
    def format_value(value)
      value = [value.begin, value.end] if value.is_a? Range
      super(value)
    end
  end
end
