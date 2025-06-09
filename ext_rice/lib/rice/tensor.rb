module Tensor
  class InvalidRanges < ::StandardError; end

  def self.types
    @@types ||= ExtRice.config.template[:numeric_types].keys.map{ |name| Tensor::Type.const_get(name) }
  end

  def self.build(type, ...)
    const_get(type.to_s).new(...)
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
end
