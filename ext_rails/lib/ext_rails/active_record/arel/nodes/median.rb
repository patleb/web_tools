module Arel
  module Nodes
    class Median < Arel::Nodes::Percentile
      def initialize(expr, aliaz = nil)
        super(expr, 0.5, aliaz)
      end
    end
  end
end
