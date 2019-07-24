module VirtualType
  class List < Kaminari::PaginatableArray
    TABLE    = /(?:"?(\w+)"?\.)/.freeze
    COLUMN   = /"?(\w+)"?/.freeze
    OPERATOR = /(<=|>=|<|>)/.freeze
    VALUE    = /'?([^']+)'?/.freeze
    COMPARE  = /^\s*#{TABLE}?#{COLUMN}\s*#{OPERATOR}\s*#{VALUE}\s*$/.freeze

    class_attribute :to_types

    alias_method :count_estimate, :size

    def initialize(original_array = [], limit: original_array.size, offset: nil, total_count: nil, padding: nil)
      super
    end

    def merge(scope)
      self.class.new(self & scope)
    end

    def take(n = 1)
      n == 1 ? first : self.class.new(super)
    end

    def distinct
      self.class.new(uniq)
    end

    def reverse_order
      self.class.new(reverse)
    end

    def reorder(*args)
      attribute = args.first.sub(TABLE, '').tr('"', '').to_sym
      self.class.new(sort_by(&attribute))
    end

    def where(query = nil, *params)
      if query.nil?
        self
      elsif query.is_a? Hash
        column, value = query.first
        value = cast_value(column, value)
        if value.is_a? Array
          self.class.new(select{ |item| value.include? item.public_send(column) })
        else
          self.class.new([find{ |item| item.public_send(column) == value }].compact)
        end
      elsif params.empty?
        self
      elsif (compare = query.match(COMPARE))
        _query, _table, column, operator, _value = compare.to_a
        value = cast_value(column, params.last)
        self.class.new(select{ |item| item.public_send(column).public_send(operator, value) })
      else
        search = params.last.gsub(/(^%|%$)/, '').downcase
        attributes = query.gsub(TABLE, '').gsub(/(ILIKE|=) \?/, '').tr('(")', '').split('OR').map(&:strip)
        self.class.new(select{ |item| attributes.any?{ |attr| item.send(attr).to_s.downcase.include?(search) } })
      end
    end

    def method_missing(method, *args, &block)
      self
    end

    def respond_to_missing?(method, _include_private = false)
      true
    end

    private

    def cast_value(column, value)
      case value
      when Array
        value.map{ |item| cast_value(column, item) }
      when nil
        value
      else
        to_type = (self.to_types ||= {})[column.to_sym] ||=
          case first.public_send(column)
          when Integer        then :to_i
          when BigDecimal     then :to_d
          when Float          then :to_f
          when Boolean        then :to_b
          when DateTime, Time then :to_time
          when Date           then :to_date
          else                     :to_s
          end
        value.public_send(to_type)
      end
    end
  end
end
