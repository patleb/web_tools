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

      def write(values, start: nil, stride: nil)
        if values.is_a? Numo::NArray
          raise "not Numo::#{type}" if values.class.name.demodulize != type.to_s
          super(values, Array.wrap(start), Array.wrap(stride))
        else
          write_s(Array(values).map(&:to_s), start || 0, stride || 1)
        end
      end

      def read(at: nil, start: at, count: nil, stride: nil)
        if start.blank? && count.blank? && stride.blank?
          super(Array.new(dims_count, 0), shape, [])
        else
          start = Array.wrap(start)
          values = super(start, Array.wrap(count), Array.wrap(stride))
          values = values.to_a.dig(*Array.new(start.size, 0)) if at
          values
        end
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
      att = atts[name] or raise MissingAttribute, name
      att.read
    end

    def delete_att(name)
      att = atts[name] or raise MissingAttribute, name
      @atts = nil
      att.destroy
    end

    private :write_att_s, :write_s
  end
end
