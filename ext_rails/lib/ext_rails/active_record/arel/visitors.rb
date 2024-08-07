module Arel
  module Visitors
    PostgreSQL.class_eval do
      private

      def visit_Arel_Nodes_Median(o, collector)
        visit_Arel_Nodes_Percentile(o, collector)
      end

      def visit_Arel_Nodes_Percentile(o, collector)
        collector << "PERCENTILE_CONT(#{o.percentile}) WITHIN GROUP (ORDER BY "
        collector = inject_join(o.expressions, collector, ", ") << ")"
        if o.alias
          collector << " AS "
          visit o.alias, collector
        else
          collector
        end
      end
    end
  end
end
