# frozen_string_literal: true

MonkeyPatch.add{['activerecord', 'lib/active_record/relation/calculations.rb', '6f9b774524ed078131e64b3bd8decee570fdb53dfc42f4b8c9dadb9e99c0ad81']}

module ActiveRecord::Relation::WithCalculate
  self::QUERYING_METHODS = [
    :stddev, :variance, :median, :percentile, :count_estimate,
    :group_by_period, :top_group_calculate, :calculate_from, :calculate_multi
  ].freeze

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

  def count_estimate
    return 0 if none? # values[:extending]&.include? ActiveRecord::NullRelation

    sql = limit(nil).offset(nil).reorder(nil).to_sql
    connection.select_value("SELECT count_estimate(#{connection.quote(sql)})")
  end

  # NOTE must be used with an aggregate method like #calculate
  def group_by_period(period, column: :created_at, reverse: false, time_range: nil)
    column = klass.quote_column(column)
    group_clause = case period
      when :minute_of_hour then "EXTRACT(MINUTE FROM #{column})::INTEGER"
      when :hour_of_day    then "EXTRACT(HOUR FROM #{column})::INTEGER"
      when :day_of_week    then "EXTRACT(DOW FROM #{column})::INTEGER"
      when :day_of_month   then "EXTRACT(DAY FROM #{column})::INTEGER"
      when :day_of_year    then "EXTRACT(DOY FROM #{column})::INTEGER"
      when :month_of_year  then "EXTRACT(MONTH FROM #{column})::INTEGER"
      when :week
        "(DATE_TRUNC('day', #{column} - INTERVAL '1 day' * ((13 + EXTRACT(DOW FROM #{column})::INTEGER) % 7)))"
      when ActiveSupport::Duration, Numeric
        period = period.to_i
        "TO_TIMESTAMP(FLOOR(EXTRACT(EPOCH FROM #{column}) / #{period}) * #{period})"
      else
        ["DATE_TRUNC(?, #{column})", period]
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
    relation = order(column_alias_for(group_clause) => (reverse ? :desc : :asc))
    relation.where(*where_clause).group(group_clause)
  end

  def top_group_calculate(*groups, operation, column: nil, arg: nil, reverse: true)
    order("1 #{reverse ? 'DESC' : 'ASC'}").order_group(*groups).calculate(operation, column, arg)
  end

  def calculate_from(operation, from, from_operation, from_column, from_arg = nil, distinct: nil, arg: nil)
    select = operation_sql(from_operation, from_column, from.distinct_value || from_arg)
    from = from.distinct(false)
    from.select_values = from.group_values_as
    from.select_values << (from_column ? "#{select} AS result" : "#{select.sub(/\*\)$/, '')}\\1) AS result")
    relation = base_class.unscoped.from("(#{from.to_sql}) AS t")
    relation = relation.distinct if distinct
    relation.calculate(operation, 'result', arg)
  end

  def calculate_multi(columns)
    selects = columns.map{ |operation_column_arg| operation_sql(*operation_column_arg).sql_safe }
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

  def calculate(operation, column, arg = nil)
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

  protected

  def group_values_as
    group_values.map{ |field| "#{field} AS #{column_alias_for(field)}".sql_safe }
  end

  private

  def column_alias_for(field)
    ActiveRecord::Calculations::ColumnAliasTracker.new(connection).alias_for(field.to_s.downcase)
  end

  def perform_calculation(operation, column, arg = nil)
    case (operation = operation.to_s.downcase)
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
      column.public_send(operation, arg)
    else
      super
    end
  end

  def operation_sql(operation, column, arg = nil)
    operation = Arel.star.send(operation, *Array.wrap(arg)).to_sql
    if (column = column.to_s).present?
      unless column.exclude?('::') || operation.upcase.start_with?('COUNT')
        operation << '::' << column.split('::').last
      end
      operation.sub! '*', klass.quote_column(column)
    end
    operation
  end
end
