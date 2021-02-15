require_rel 'relation'

# TODO https://github.com/jhollinger/occams-record
# TODO https://docs.timescale.com/v0.9/using-timescaledb/reading-data#approximate-row-count
ActiveRecord::Relation.class_eval do
  prepend self::WithAtomicOperations
  include self::WithCalculate
  prepend self::WithJsonAttribute
  prepend self::WithReturningColumn

  def select_without(*fields)
    select(*(column_names - fields.map(&:to_s)))
  end

  def where_not(*args)
    where.not(*args)
  end

  def order_group(*columns, reverse: false, distinct: nil, min: nil)
    aliases = columns.map{ |field| column_alias_for(field.to_s.dup).downcase }
    relation = reverse ? order(aliases.map{ |column| [column, :desc] }.to_h) : order(*aliases)
    relation = relation.group(*columns)
    if min
      if distinct
        distinct = distinct.is_a?(Arel::Nodes::SqlLiteral) ? distinct : klass.quote_column(distinct)
        count = "COUNT(DISTINCT #{distinct}) >= ?"
      else
        count = "COUNT(*) >= ?"
      end
      relation = relation.having(count, min.to_i)
    end
    relation = relation.distinct if distinct
    relation
  end

  def count_estimate
    return 0 if none? # values[:extending]&.include? ActiveRecord::NullRelation

    sql = limit(nil).offset(nil).reorder(nil).to_sql
    connection.exec_query("EXPLAIN #{sql}").first["QUERY PLAN"].match(/rows=(\d+)/)[1].to_i
  end
end

ActiveRecord::Base.class_eval do
  class << self
    delegate :select_without, :where_not, :order_group, :count_estimate, to: :all
    delegate :stddev, :variance, :median, :percentile, to: :all
    delegate :group_by_period, :top_group_calculate, :calculate_from, :calculate_multi, to: :all
  end
end
