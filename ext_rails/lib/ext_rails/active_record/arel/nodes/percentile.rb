module Arel
  module Nodes
    class Percentile < Arel::Nodes::Function
      attr_accessor :percentile, :discrete

      def initialize(expr, percentile, discrete = false, aliaz = nil)
        super(expr, aliaz)
        @percentile = percentile
        @discrete = discrete
      end

      def hash
        [@expressions, @alias, @distinct, @percentile, @discrete].hash
      end

      def eql?(other)
        super && self.percentile == other.percentile && self.discrete == other.discrete
      end
    end
  end
end
