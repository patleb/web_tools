### References
# https://github.com/begriffs/pg_rational/blob/master/pg_rational.c
class Rational
  class LowerOrUpperNegative < ArgumentError; end
  class LowerGreaterOrEqualToUpper < ArgumentError; end

  LO = Rational(0, 1).freeze
  HI = Float::MAX.rationalize.freeze

  def self.intermediate(lower, upper)
    lower ||= LO
    upper ||= HI
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
