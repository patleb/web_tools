module Tensor
  ExtRice.config.compile_vars[:numeric_types].each_key do |name|
    const_get(name).class_eval do
      module self::WithOverrides
        def initialize(*values, **options)
          values = values.first if values.first.is_a? Array
          super(values, **options)
        end

        def shape
          super.to_a
        end

        def [](*indexes)
          super(indexes)
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
          shape = self.shape.select_map.with_index do |all, i|
            case (count = shape[i])
            when false then next
            when true  then all
            else count
            end
          end
          super
        end

        def seq(start = 0)
          super
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

      def _from_sql_(string)
        # TODO
      end
    end
  end
end
