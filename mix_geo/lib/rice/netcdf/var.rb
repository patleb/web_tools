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

      def dig(name, index = nil)
        att = atts[name]
        return att.dig(index) if index
        att
      end

      def write(values, start: nil, stride: nil)
        if values.is_a? Numo::NArray
          raise "not Numo::#{type}" if values.class.name.demodulize != type.to_s
          super(values, Array.wrap(start), Array.wrap(stride))
        else
          write_s(Array(values).map(&:to_s), start || 0, stride || 1)
        end
      end

      def read(at: nil, start: nil, count: nil, stride: nil)
        if at
          values = super(Array(at), [], []).to_a
          if type != Type::String
            values.dig(*Array.new(dims_count, 0))
          else
            values.first
          end
        elsif start.blank? && count.blank? && stride.blank?
          if type != Type::String
            super(Array.new(dims_count, 0), shape, [])
          else
            super([0], [shape.first], [])
          end
        else
          super(Array.wrap(start), Array.wrap(count), Array.wrap(stride))
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
