module Tensor
  ExtRice.config.template[:numeric].each_key do |tensor_type|
    const_get(tensor_type).class_eval do
      module self::WithOverrides
        extend ActiveSupport::Concern

        class_methods do
          def from_sql(values, *shape, fill_value: nil)
            shape = shape.first if shape.first.is_a? Array
            super(values, shape, fill_value)
          end
        end

        def initialize(*values, **options)
          values = values.first if values.first.is_a? Array
          super(values, **options)
        end

        def [](*indexes)
          indexes.size == 1 ? super(indexes.first) : super(indexes)
        end

        def []=(*indexes, value)
          super(indexes, value)
        end

        def slice(*ranges, start: nil, count: nil, stride: nil)
          if ranges.empty?
            super
          else
            start, count, shape = Tensor.to_slice_args(self.shape, *ranges)
            super(start: start, count: count).reshape(shape)
          end
        end

        def reshape(*shape)
          shape = shape.first if shape.first.is_a? Array
          return super(shape) unless shape.size == rank
          shape = self.shape.select_map.with_index do |all, i|
            case (count = shape[i])
            when false then next
            when true  then all
            else count
            end
          end
          super(shape)
        end

        def reverse(axis = nil)
          super
        end

        def seq(start = nil)
          super
        end

        def to_sql(before: nil, after: nil, nulls: nil)
          super(before, after, nulls)
        end
      end
      prepend self::WithOverrides

      def self.[](*values)
        case (first = values.first)
        when Range
          values = first.to_a
          shape = [values.size]
        when Array
          shape = [values.size]
          loop do
            shape << first.size
            break unless (first = first.first).is_a? Array
          end
          values = values.flatten
        else
          shape = [values.size]
        end
        new(values, shape: shape)
      end

      def to_a
        values.to_a
      end

      def to_s(limit = 120)
        to_string(limit)
      end
    end
  end
end
