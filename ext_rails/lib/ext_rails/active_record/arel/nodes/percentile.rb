module Arel
  module Nodes
    class Percentile < Arel::Nodes::Function
      attr_accessor :percentile

      def initialize(expr, percentile, aliaz = nil)
        super(expr, aliaz)
        @percentile = percentile
      end

      def hash
        [@expressions, @alias, @distinct, @percentile].hash
      end

      def eql?(other)
        super && self.percentile == other.percentile
      end
    end
  end
end
