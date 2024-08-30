# frozen_string_literal: true

module ActiveRecord::Relation::WithJsonAttribute
  extend ActiveSupport::Concern

  QUERYING_METHODS = [:where_not].freeze
  POSTGRESQL_OPERATORS = /^(!|NOT )?(=|~\*?|[<>]=?|IS( NOT)?|I?LIKE|SIMILAR TO|BETWEEN|IN|ANY|ALL)$/i

  prepended do
    delegate :json_accessors, :json_key, to: :klass
  end

  def select(*attributes, as: true)
    return super(*attributes) unless json_accessors
    super(*attributes.map{ |name| json_key(name, as: as) })
  end

  def where(*args)
    return super unless (attributes = args.first).is_a?(Hash) && attributes.present?
    scopes = attributes.each_with_object([]) do |(name, value), result|
      if json_attribute? name
        operator, value = extract_operator(value)
        binds, *values = case value
          when Array then ['(?)', value]
          when Range then ['(?) AND (?)', value.min, value.max]
          else            ['?', value]
          end
        result << super("#{json_key(name)} #{operator} #{binds}", *values)
      else
        result << super(name => value)
      end
    end
    scopes.reduce(&:merge)
  end

  def where_not(*args)
    return super unless (attributes = args.first).is_a?(Hash) && attributes.present?
    scopes = attributes.each_with_object([]) do |(name, value), result|
      if json_attribute? name
        operator, value = extract_operator(value)
        operator = case operator
          when /^(=|~\*?)$/  then "!#{$1}"
          when /^!(=|~\*?)$/ then $1
          when '<'           then '>='
          when '>'           then '<='
          when '<='          then '>'
          when '>='          then '<'
          when 'IS'          then 'IS NOT'
          when 'IS NOT'      then 'IS'
          when /^NOT (\w+)$/ then $1
          else "NOT #{operator.upcase}"
          end
        result << where(name => [operator, value])
      else
        result << where.not(name => value)
      end
    end
    scopes.reduce(&:merge)
  end

  def order(*args, **opts)
    return super unless json_accessors
    super(*args.map{ |name| json_key(name) }, **opts.transform_keys{ |name| json_key(name) })
  end

  def group(*attributes)
    return super unless json_accessors
    super(*attributes.map{ |name| json_key(name) })
  end

  def order_group(*attributes, **)
    return super unless json_accessors
    super(*attributes.map{ |name| json_key(name) }, **)
  end

  def calculate_from(operation, from, from_operation, from_column, from_arg = nil, **)
    return super unless json_accessors
    super(operation, from, from_operation, json_key(from_column), from_arg, **)
  end

  def calculate_multi(columns)
    return super unless json_accessors
    super(columns.map{ |(operation, column, *args)| [operation, json_key(column), *args] })
  end

  def calculate(operation, column = nil, *)
    return super unless json_accessors && column
    super(operation, json_key(column), *)
  end

  def pluck(*attributes)
    return super unless json_accessors
    super(*attributes.map{ |name| json_key(name, as: true) })
  end

  def pick(*attributes)
    return super unless json_accessors
    super(*attributes.map{ |name| json_key(name, as: true) })
  end

  private

  def extract_operator(value)
    operator, value = value if value.is_a?(Array) && value[0].is_a?(String) && value[0].match?(POSTGRESQL_OPERATORS)
    operator ||= case value
      when nil   then 'IS'
      when Array then 'IN'
      when Range then 'BETWEEN'
      else '='
      end
    [operator.upcase, value]
  end
end
