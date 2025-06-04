module Tensor
  class InvalidRanges < ::StandardError; end

  def self.types
    @@types ||= ExtRice.config.compile_vars[:numeric_types].keys.map{ |name| Tensor::Type.const_get(name) }
  end

  def self.to_slice_args(src_shape, *dst_ranges)
    raise InvalidRanges if dst_ranges.size > (dims_count = src_shape.size)
    start, count, shape = dst_ranges.each_with_object([[], [], []]).with_index do |(range, (start, count, shape)), i|
      case range
      when Range
        start << (at = range.begin)
        if (size = range.size).infinite?
          size = src_shape[i] - at
        end
        count << size
        shape << true
      when true
        start << 0
        count << src_shape[i]
        shape << true
      else
        start << range
        count << 1
        shape << false
      end
    end
    if (rest_count = (dims_count - (partial_count = start.size))) > 0
      start.concat(Array.new(rest_count, 0))
      count.concat(src_shape.to_a[partial_count..])
      shape.concat(Array.new(rest_count, true))
    end
    [start, count, shape]
  end

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
        values = values.first.to_a if values.first.is_a? Range
        new(values, shape: [values.size])
      end

      def to_a
        values.to_a
      end
    end
  end
end
