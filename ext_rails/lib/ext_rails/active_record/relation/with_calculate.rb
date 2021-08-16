module ActiveRecord::Relation::WithCalculate
  def group_by_period(period, column: :created_at, reverse: false, seconds: nil, time_range: nil)
    column = klass.quote_column(column)
    group_clause = case period
      when :minute_of_hour then "EXTRACT(MINUTE FROM #{column})::INTEGER"
      when :hour_of_day    then "EXTRACT(HOUR FROM #{column})::INTEGER"
      when :day_of_week    then "EXTRACT(DOW FROM #{column})::INTEGER"
      when :day_of_month   then "EXTRACT(DAY FROM #{column})::INTEGER"
      when :day_of_year    then "EXTRACT(DOY FROM #{column})::INTEGER"
      when :month_of_year  then "EXTRACT(MONTH FROM #{column})::INTEGER"
      when :week           then "(DATE_TRUNC('day', #{column} - INTERVAL '1 day' * ((13 + EXTRACT(DOW FROM #{column})::INTEGER) % 7)))"
      when :custom         then ["TO_TIMESTAMP(FLOOR(EXTRACT(EPOCH FROM #{column}) / ?) * ?)", seconds, seconds]
      else                      ["DATE_TRUNC(?, #{column})", period]
      end
    group_clause = group_clause.is_a?(Array) ? sanitize_sql_array(group_clause) : group_clause
    where_clause = case time_range
      when Range
        if time_range.end
          op = time_range.exclude_end? ? "<" : "<="
          if time_range.begin
            ["#{column} >= ? AND #{column} #{op} ?", time_range.begin, time_range.end]
          else
            ["#{column} #{op} ?", time_range.end]
          end
        else
          ["#{column} >= ?", time_range.begin]
        end
      else
        ["#{column} IS NOT NULL"]
      end
    relation = order(column_alias_for(group_clause.to_s.dup).downcase => (reverse ? :desc : :asc))
    relation.where(*where_clause).group(group_clause)
  end

  def top_group_calculate(*groups, operation, column: nil, reverse: true, **opts)
    order("1 #{reverse ? 'DESC' : 'ASC'}").order_group(*groups, **opts).calculate(operation, column)
  end

  def calculate_from(operation, from, from_operation, from_column, distinct: nil)
    select = operation_sql(from_operation, from_column, from.distinct_value) # /^SELECT (.+?)(?= FROM)/
    from.distinct!(false)
    from.select_values = from.group_values_as
    from.select_values << (from_column ? "#{select} AS result" : "#{select.sub(/\*\)$/, '')}\\1) AS result")
    relation = base_class.from("(#{from.to_sql}) AS t")
    relation = relation.distinct if distinct
    relation.calculate(operation, 'result')
  end

  def stddev(column)
    calculate(:stddev, column)
  end

  def variance(column)
    calculate(:variance, column)
  end

  def median(column, discrete = false)
    calculate(:median, column, discrete)
  end

  def percentile(column, percentile, discrete = false)
    calculate(:percentile, column, percentile, discrete)
  end

  def calculate_multi(columns)
    selects = columns.map{ |operation_column_args| operation_sql(*operation_column_args).sql_safe }
    relation = distinct!(false)
    if group_values.any?
      select_aliases = group_values_as
      selects.concat select_aliases
      select_range = 0...columns.size
      group_range = columns.size...(columns.size + select_aliases.size)
      Hash[relation.pluck(*selects).map do |row|
        key = row[group_range]
        key = key.first if key.size == 1
        [key, row[select_range].map!{ |value| value || 0 }]
      end]
    else
      relation.pluck(*selects).map!{ |row| row.map!{ |value| value || 0 } }
    end
  end

  def calculate(operation, column = nil, *args)
    case operation
    when Array
      calculate_multi(operation)
    when :percentile
      if has_include? column
        apply_join_dependency.calculate(operation, column, *args)
      else
        perform_calculation(operation, column, *args)
      end
    else
      super(operation, column)
    end
  end

  def group_values_as
    group_values.map{ |field| "#{field} AS #{column_alias_for(field.to_s.dup).downcase}".sql_safe }
  end

  private

  def perform_calculation(operation, column, *args)
    case (operation = operation.to_s)
    when 'percentile'
      if group_values.any?
        execute_grouped_calculation(operation, column, *args)
      else
        execute_simple_calculation(operation, column, *args)
      end
    else
      super(operation, column)
    end
  end

  def operation_over_aggregate_column(column, operation, *args)
    case operation
    when 'percentile'
      column.send(operation, *args)
    else
      super
    end
  end

  def type_cast_calculated_value(value, operation = nil)
    case operation
    when 'stddev', 'variance', 'median', 'percentile' then value&.respond_to?(:to_d) ? value.to_d : value
    else super
    end
  end

  def operation_sql(operation, column = nil, *args)
    operation = Arel.star.send(operation, *args.compact).to_sql
    if (column = column.to_s).present?
      operation.sub! '*', klass.quote_column(column)
      operation << '::' << column.split('::').last if column.include? '::'
    end
    operation
  end
end
