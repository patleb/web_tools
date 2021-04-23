module VirtualRecord
  class Relation < Kaminari::PaginatableArray
    TABLE    = /(?:"?(\w+)"?\.)/.freeze
    COLUMN   = /"?(\w+)"?/.freeze
    OPERATOR = /(<=|>=|<|>)/.freeze
    VALUE    = /'?([^']+)'?/.freeze
    COMPARE  = /^\s*#{TABLE}?#{COLUMN}\s*#{OPERATOR}\s*#{VALUE}\s*$/.freeze

    alias_method :count_estimate, :size
    alias_method :exists?, :any?

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

    def order(*args)
      attribute = args.first.sub(TABLE, '').tr('"', '').to_sym
      self.class.new(sort_by(&attribute))
    end
    alias_method :reorder, :order

    def where(query = nil, *params)
      if query.nil?
        self
      elsif query.is_a? Hash
        result = query.reduce(self) do |memo, (column, value)|
          value = cast_value(column, value)
          if value.is_a? Array
            memo.select{ |item| value.include? item.public_send(column) }
          else
            [memo.find{ |item| item.public_send(column) == value }].compact
          end
        end
        self.class.new(result)
      elsif params.empty?
        self
      elsif (compare = query.match(COMPARE))
        _query, _table, column, operator, _value = compare.to_a
        value = cast_value(column, params.last)
        self.class.new(select{ |item| item.public_send(column).public_send(operator, value) })
      else
        search = params.last.gsub(/(^%|%$)/, '').downcase
        attributes = query.gsub(TABLE, '').gsub(/ (I?LIKE|=) \?/i, ' ').tr('(")', '').split('OR').map(&:strip)
        self.class.new(select{ |item| attributes.any?{ |attr| item.public_send(attr).to_s.downcase.include?(search) } })
      end
    end

    def method_missing(name, *args, **options, &block)
      if klass.respond_to? name
        klass.use(self) do
          klass.public_send(name, *args, **options, &block)
        end
      else
        self
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
        klass.virtual_columns_hash[column.to_s].type_cast(value)
      end
    end
  end
end
