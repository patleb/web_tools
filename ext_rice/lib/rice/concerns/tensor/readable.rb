module Tensor
  module Readable
    def read(start: nil, count: nil, stride: nil)
      if start.blank? && count.blank? && stride.blank?
        numeric? ? super(Array.new(dims_count, 0), shape, []) : super([0], [shape.first], [])
      else
        super(Array.wrap(start), Array.wrap(count), Array.wrap(stride))
      end
    end

    def at(*indexes)
      indexes.map do |index|
        values = read(start: Array(index)).to_a
        numeric? ? values.dig(*Array.new(dims_count, 0)) : values.first
      end
    end

    def [](*ranges)
      return read if ranges.empty?
      start, count, shape = Tensor.to_slice_args(self.shape, *ranges)
      read(start: start, count: count).reshape(shape)
    end
  end
end
