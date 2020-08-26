### References
# https://github.com/begriffs/pg_rational/blob/master/pg_rational.c
class Rational
  class LowerOrUpperNegative < ArgumentError; end
  class LowerGreaterOrEqualToUpper < ArgumentError; end

  INTERMEDIATE_BEGIN = Rational(1)

  def self.intermediate(lower, upper)
    if lower.nil? && upper
      lower = upper.ceil - 1.0
      lower <= 0.0 ? lower = 0.0 : (return lower)
    end
    if lower && upper.nil?
      return lower.floor + 1.0
    end
    lower = lower.rationalize unless lower.is_a? Rational
    upper = upper.rationalize unless upper.is_a? Rational
    raise LowerOrUpperNegative if lower.negative? || upper.negative?
    raise LowerGreaterOrEqualToUpper if lower >= upper
    loop do
      value = Rational(lower.numerator + upper.numerator, lower.denominator + upper.denominator)
      if value <=> lower < 1
        lower = value
      elsif value <=> upper > -1
        upper = value
      else
        return value
      end
    end
  end
end
