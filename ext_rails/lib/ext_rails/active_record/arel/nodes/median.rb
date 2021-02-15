module Arel
  module Nodes
    class Median < Arel::Nodes::Percentile
      def initialize(expr, discrete = false, aliaz = nil)
        super(expr, 0.5, discrete, aliaz)
      end
    end
  end
end
