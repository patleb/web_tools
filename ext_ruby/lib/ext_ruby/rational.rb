class Rational
  def self.intermediate(lower, upper)
    (lower + (upper - lower) / 2.0).rationalize(1e-12)
  end
end
