module Tensor
  module Writable
    def write(values, start: nil, stride: nil)
      if values.is_a? Tensor::Base
        raise "not Tensor::#{type}" if values.class.name.demodulize != type.to_s
        super(values, Array.wrap(start), Array.wrap(stride))
      else
        write_s(Array(values).map(&:to_s), start || 0, stride || 1)
      end
    end

    def []=(*ranges, values)
      return write(values) if ranges.empty?
      start, count, _shape = Tensor.to_slice_args(self.shape, *ranges)
      begin
        shape_was = values.shape
        values.reshape(count)
        write(values, start: start)
      ensure
        values.reshape(shape_was)
      end
    end
  end
end
