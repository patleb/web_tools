class Rational
  class LowerAndUpperNil < ArgumentError; end
  class LowerGreaterOrEqualToUpper < ArgumentError; end

  def self.intermediate(lower, upper)
    raise LowerAndUpperNil if lower.nil? && upper.nil?
    raise LowerGreaterOrEqualToUpper if lower >= upper

    if lower.nil? || lower == -Float::INFINITY
      (upper.ceil - 1.0).to_r
    elsif upper.nil? || upper == Float::INFINITY
      (lower.floor + 1.0).to_r
    else
      (lower + (upper - lower) / 2.0).rationalize(1e-12)
    end
  end
end
