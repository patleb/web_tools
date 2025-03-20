module NetCDF
  Var.class_eval do
    module self::WithOverrides
      def name=(new_name)
        super(new_name.to_s)
      end

      def dims
        @dims ||= super.map{ [it.name, it] }.to_hwia
      end

      def atts
        @atts ||= super.map{ [it.name, it] }.to_hwia
      end

      def write_att(name, values)
        @atts = nil
        if values.is_a? Numo::NArray
          super(name.to_s, values.class.name.demodulize, values)
        else
          write_att_s(name.to_s, values.to_s)
        end
      end

      def write(values, _starts = [], _strides = [], starts: _starts, strides: _strides)
        if values.is_a? Numo::NArray
          raise "not Numo::#{type}" if values.class.name.demodulize != type.to_s
          super(values, starts, strides)
        else
          write_s(Array(values).map(&:to_s), starts.presence || 0, strides.presence || 1)
        end
      end

      def read(_starts = [], _counts = [], _strides = [], starts: _starts, counts: _counts, strides: _strides)
        super(starts, counts, strides)
      end

      def fill_value
        return unless (value = super)
        value[0]
      end

      def set_fill_value(value, _type: nil)
        @atts = nil
        if value.is_a? Numo::NArray
          raise "not Numo::#{type}" if value.class.name.demodulize != type.to_s
        elsif _type
          value = Numo.const_get(_type)[value]
        end
        super(value)
      end
    end
    prepend self::WithOverrides

    def read_att(name)
      att = atts[name] || raise("missing attribute [#{name}]")
      att.read
    end

    def delete_att(name)
      att = atts[name] || raise("missing attribute [#{name}]")
      @atts = nil
      att.destroy
    end

    private :write_att_s, :write_s
  end
end
