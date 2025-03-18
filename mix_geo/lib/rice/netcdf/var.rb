module NetCDF
  Var.class_eval do
    module self::WithOverrides
      def dims
        @dims ||= super.map{ [it.name, it] }.to_hwia
      end

      def atts
        @atts ||= super.map{ [it.name, it] }.to_hwia
      end

      def write_att(name, values)
        if values.is_a? Numo::NArray
          super(name.to_s, values.class.name.demodulize, values)
        else
          write_att_s(name.to_s, values.to_s)
        end
      end

      def write(values, _starts = [], _counts = [], _strides = [], starts: _starts, counts: _counts, strides: _strides)
        if values.is_a? Numo::NArray
          raise "not Numo::#{type}" if values.class.name.demodulize != type.to_s
          { starts: starts.size, counts: counts.size, strides: strides.size }.each do |name, size|
            raise "dims.size != #{name}.size [#{size}]" unless size.zero? || size == dims.size
          end
          super(values, starts, counts, strides)
        else
          write_s(Array(values).map(&:to_s))
        end
      end

      def fill_value
        return unless (value = super)
        value[0]
      end

      def set_fill_value(value)
        if value.is_a? Numo::NArray
          raise "not Numo::#{type}" if value.class.name.demodulize != type.to_s
        else
          set_fill_value_s(value)
        end
      end
    end
    prepend self::WithOverrides

    def delete_att(name)
      att = atts[name] || raise("missing attribute [#{name}]")
      att.destroy
    end

    private :write_att_s, :write_s, :set_fill_value_s
  end
end
