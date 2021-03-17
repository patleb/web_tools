module Arel
  module Visitors
    Dot.class_eval do
      private

      alias :visit_Arel_Nodes_Median     :function
      alias :visit_Arel_Nodes_Percentile :function
    end

    ToSql.class_eval do
      private

      def visit_Arel_Nodes_Median(o, collector)
        visit_Arel_Nodes_Percentile(o, collector)
      end

      def visit_Arel_Nodes_Percentile(o, collector)
        collector << "PERCENTILE_#{o.discrete ? 'DISC' : 'CONT'}(#{o.percentile}) WITHIN GROUP (ORDER BY "
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
