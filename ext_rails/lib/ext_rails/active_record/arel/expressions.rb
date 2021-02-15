module Arel
  module Expressions
    def stddev
      ArelExtensions::Nodes::Std.new [self]
    end

    def variance
      ArelExtensions::Nodes::Variance.new [self]
    end

    def median(discrete = false)
      Nodes::Percentile.new [self], 0.5, discrete
    end

    def percentile(value, discrete = false)
      Nodes::Percentile.new [self], value, discrete
    end
  end
end
