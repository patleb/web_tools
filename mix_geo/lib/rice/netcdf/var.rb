module NetCDF
  Var.class_eval do
    module self::WithOverrides
      def name=(new_name)
        super(new_name.to_s)
      end

      def dims
        @dims ||= super.map{ |dim| [dim.name, dim] }.to_hwia
      end

      def atts
        @atts ||= super.map{ |att| [att.name, att] }.to_hwia
      end

      def dim(name)
        super(name.to_s)
      end

      def att(name)
        super(name.to_s)
      end

      def write_att(name, values)
        @atts = nil
        if values.is_a? Tensor::Base
          super(name.to_s, values.class.name.demodulize, values)
        else
          write_att_s(name.to_s, values.to_s)
        end
      end

      def write(values, start: nil, stride: nil)
        if values.is_a? Tensor::Base
          raise "not Tensor::#{type}" if values.class.name.demodulize != type.to_s
          super(values, Array.wrap(start), Array.wrap(stride))
        else
          write_s(Array(values).map(&:to_s), start || 0, stride || 1)
        end
      end

      def read(start: nil, count: nil, stride: nil)
        tensor = if start.blank? && count.blank? && stride.blank?
          numeric? ? super(Array.new(dims_count, 0), shape, []) : super([0], [shape.first], [])
        else
          super(Array.wrap(start), Array.wrap(count), Array.wrap(stride))
        end
        tensor.fill_value = fill_value || default_fill_value if numeric?
        tensor
      end

      def default_fill_value
        NetCDF.const_get("FILL_#{type.to_s.upcase}")
      end

      def fill_value
        return unless (value = super)
        value[0]
      end

      def set_fill_value(value, _type: nil)
        @atts = nil
        if value.is_a? Tensor::Base
          raise "not Tensor::#{type}" if value.class.name.demodulize != type.to_s
        elsif _type
          value = Tensor.const_get(_type)[value]
        end
        super(value)
      end
    end
    prepend self::WithOverrides

    def at(*indexes)
      indexes.map do |index|
        values = read(start: Array(index)).to_a
        numeric? ? values.dig(*Array.new(dims_count, 0)) : values.first
      end
    end

    def [](*ranges)
      start, count, shape = Tensor.to_slice_args(self.shape, *ranges)
      read(start: start, count: count).reshape(shape)
    end

    def read_att(name)
      att(name).read
    end

    def delete_att(name)
      @atts = nil
      att(name).destroy
    end

    def dig(name, *indexes)
      return unless (att = atts[name])
      return att.dig(*indexes) unless indexes.empty?
      att.read
    end

    def numeric?
      type != Type::String
    end

    private :write_att_s, :write_s
  end
end
