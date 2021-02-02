module Arel
  module Expressions
    def stddev
      ArelExtensions::Nodes::Std.new [self]
    end

    def variance
      ArelExtensions::Nodes::Variance.new [self]
    end

    def median
      Nodes::Percentile.new [self], 0.5
    end

    def percentile(value)
      Nodes::Percentile.new [self], value
    end
  end
end
