MonkeyPatch.add{['arel_extensions', 'lib/arel_extensions/nodes/std.rb', '25c24b0a7711858b087f200ee2935d89cc224522c1fa593c0a1f1837aa7e38ab']}

module Arel
  module Expressions
    def stddev
      ArelExtensions::Nodes::Std.new(self, unbiased: true)
    end

    def variance
      ArelExtensions::Nodes::Variance.new(self, unbiased: true)
    end

    def median
      Nodes::Percentile.new [self], 0.5
    end

    # NOTE: PERCENTILE_DISC doesn't give consistent results
    def percentile(value)
      Nodes::Percentile.new [self], value
    end
  end
end
