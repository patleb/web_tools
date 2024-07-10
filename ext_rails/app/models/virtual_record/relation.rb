# frozen_string_literal: true

module VirtualRecord
  class Relation < Array
    class UnknownOperator < ::StandardError; end

    TABLE    = /(?:"?(?:\w+)"?\.)/
    COLUMN   = /#{TABLE}?"?(\w+)"?/
    COLUMN_2 = /#{TABLE}?"?(?:\w+)"?/
    VALUE    = /\?/
    RANGE    = /#{COLUMN} (?:(NOT) BETWEEN|BETWEEN) #{VALUE} AND #{VALUE}/
    STRING   = /#{COLUMN} (?:(NOT) ILIKE|ILIKE) #{VALUE}/
    BOOLEAN  = /#{COLUMN} (?:IS NULL OR) #{COLUMN_2} (?:(!)=|=)? #{VALUE}/
    BLANK    = /#{COLUMN} (?:IS (NOT) NULL|IS NULL)/
    ARRAY    = /#{COLUMN} (?:(NOT) IN |IN) (\(#{VALUE}?(?:,#{VALUE})?\))/
    OPERATOR = /#{COLUMN} ([=!<>]=?) #{VALUE}/

    attr_reader :order_values
    attr_reader :limit_value

    alias_method :count_estimate, :size
    alias_method :exists?, :any?

    def initialize(array = [], limit: array.size, offset: 0, total_count: nil)
      limit = 1 if limit == 0
      @array, @limit_value, @offset_value, @total_count = array, limit, offset, total_count
      if @total_count
        array = array.first(@total_count)[@offset_value, @limit_value] if @total_count <= array.size
      else
        array = array[@offset_value, @limit_value]
      end
      super(array || [])
    end

    def select(*attributes, &block)
      return self.class.new(super) if attributes.empty?
      array = @array.map{ |item| item.slice(*attributes) }
      self.class.new(array, limit: @limit_value, offset: @offset_value, total_count: @total_count)
    end

    def take(n = nil)
      n ? self.class.new(super) : first
    end

    def limit(n)
      self.class.new(@array, limit: n, offset: @offset_value, total_count: @total_count)
    end

    def offset(n)
      self.class.new(@array, limit: @limit_value, offset: n, total_count: @total_count)
    end

    def total_count
      @total_count ||= @array.size
    end

    def none
      self.class.new([])
    end

    def distinct
      self.class.new(uniq)
    end

    def reverse_order
      self.class.new(reverse)
    end

    def order(column, nil_first: false)
      attribute = column.to_s.sub(TABLE, '').tr('"', '').to_sym
      nil_first, nil_last = nil_first.to_i, (!nil_first).to_i
      result = sort_by do |item|
        value = item.public_send(attribute)
        [value ? nil_first : nil_last, value]
      end
      self.class.new(result)
    end
    alias_method :reorder, :order

    def where(query = nil, *values)
      if query.blank?
        result = []
      elsif query.is_a? Hash
        result = select do |item|
          query.all? do |column, value|
            case (value = cast_value(column, value))
            when Array
              value.include? item.public_send(column)
            else
              item.public_send(column) == value
            end
          end
        end
      else
        query = query.delete_prefix('(').delete_suffix(')') if query.include? ') OR ('
        attributes = query.split(') OR (').map do |statement|
          case statement
          when RANGE    then [$1, :range,    $2,  2]
          when STRING   then [$1, :string,   $2,  1]
          when BOOLEAN  then [$1, :boolean,  $2,  1] # must be evaluated before BLANK
          when BLANK    then [$1, :blank,    $2,  0]
          when ARRAY    then [$1, :array,    $2,  $3.count('?')]
          when OPERATOR then [$1, :operator, nil, 1, $2]
          else raise UnknownOperator, statement
          end
        end
        result = select do |item|
          i = 0
          attributes.each.any? do |(name, type, not_, count, operator)|
            item_value = item.public_send(name)
            item_included = case type
              when :range
                value = (cast_value(name, values[i])..cast_value(name, values[i + 1]))
                not_ ? !value.cover?(item_value) : value.cover?(item_value)
              when :string
                item_value, value = item_value.to_s.simplify, values[i].to_s.gsub(/(^%|%$)/, '').simplify
                not_ ? item_value.exclude?(value) : item_value.include?(value)
              when :boolean
                item_value, value = item_value.to_b, values[i].to_b
                not_ ? item_value != value : item_value == value
              when :blank
                not_ ? item_value.present? : item_value.blank?
              when :array
                value = cast_value(name, values[i, count])
                not_ ? value.exclude?(item_value) : value.include?(item_value)
              when :operator
                operator = operator == '=' ? '==' : operator
                value = cast_value(name, values[i])
                item_value.public_send(operator, value)
              end
            i += count
            item_included
          end
        end
      end
      self.class.new(result)
    end

    def method_missing(name, ...)
      if klass.respond_to? name
        klass.use(self) do
          klass.public_send(name, ...)
        end
      else
        super
      end
    end

    def respond_to_missing?(method, _include_private = false)
      true
    end

    private

    def cast_value(column, value)
      case value
      when Array
        value.map{ |item| cast_value(column, item) }
      else
        column = column.to_s
        (klass.virtual_columns_hash[column] || klass.attribute_types[column]).cast(value)
      end
    end
  end
end
