module ActiveRecord::Relation::WithCalculate
  SELECT_FROM = /^SELECT (.+?)(?= FROM)/

  def order_group_calculate(*columns, operation, column, reverse: true, **opts)
    order("1 #{reverse ? 'DESC' : 'ASC'}").order_group(*columns, **opts).calculate(operation, column)
  end

  def calculate_from(operation, from_operation, from_column, from, from_distinct: nil, distinct: nil)
    select = operation_sql(from_operation, from_column, from_distinct)
    if from_column
      from = from.to_sql.sub(SELECT_FROM, "SELECT #{select} AS result")
    else
      from = from.to_sql.sub(SELECT_FROM, "SELECT #{select.sub(/\*\)$/, '')}\\1) AS result")
    end
    from = from.sub('DISTINCTDISTINCT', 'DISTINCT') # when :from_distinct is used and :from has already a distinct
    relation = base_class.from("(#{from}) AS t(result)")
    relation = relation.distinct if distinct
    relation.calculate(operation, 'result')
  end

  def stddev(column)
    calculate(:stddev, column)
  end

  def variance(column)
    calculate(:variance, column)
  end

  def median(column)
    calculate(:median, column)
  end

  def percentile(column, percentile)
    calculate(:percentile, column, percentile)
  end

  def calculate_multi(columns)
    pluck(*columns.map{ |operation_column_arg| operation_sql(*operation_column_arg).sql_safe })
  end

  def calculate(operation, column = nil, arg = nil)
    case operation
    when Array
      calculate_multi(operation)
    when :percentile
      if has_include? column
        apply_join_dependency.calculate(operation, column, arg)
      else
        perform_calculation(operation, column, arg)
      end
    else
      super(operation, column)
    end
  end

  private

  def perform_calculation(operation, column, arg = nil)
    case (operation = operation.to_s)
    when 'percentile'
      if group_values.any?
        execute_grouped_calculation(operation, column, arg)
      else
        execute_simple_calculation(operation, column, arg)
      end
    else
      super(operation, column)
    end
  end

  def operation_over_aggregate_column(column, operation, arg)
    case operation
    when 'percentile'
      column.send(operation, arg)
    else
      super
    end
  end

  def type_cast_calculated_value(value, type, operation = nil)
    case operation
    when 'stddev', 'variance', 'median', 'percentile' then value&.respond_to?(:to_d) ? value.to_d : value
    else super
    end
  end

  def operation_sql(operation, column = nil, *arg)
    operation = Arel.star.send(operation, *arg.compact).to_sql
    operation.sub!('*', column.to_s) if column
    operation
  end
end
