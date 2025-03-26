module NetCDF
  File.class_eval do
    def self.open(...)
      file = new(...)
      yield file
      file
    ensure
      file&.close
    end

    module self::WithOverrides
      def initialize(path, mode = 'r', nc4_classic: false, classic: false, share: false)
        super(path.to_s, mode, nc4_classic, classic, share)
      end

      def open(path, mode = 'r', nc4_classic: false, classic: false, share: false)
        super(path.to_s, mode, nc4_classic, classic, share)
      end

      def dims
        super.map{ [it.name, it] }.to_hwia
      end

      def vars
        super.map{ [it.name, it] }.to_hwia
      end

      def atts
        super.map{ [it.name, it] }.to_hwia
      end

      def dim(name, dim_name = nil)
        dim_name ? var(name).dim(dim_name) : super(name.to_s)
      end

      def var(name)
        super(name.to_s)
      end

      def att(name, att_name = nil)
        att_name ? var(name).att(att_name) : super(name.to_s)
      end

      def create_dim(name, *)
        super(name.to_s, *)
      end

      def create_var(name, type, dims, fill_value: nil)
        case type
        when Class
          type = type.name.demodulize if type <= Numo::NArray
        when Numo::NArray
          type = type.class.name.demodulize
        else
          type = type.to_s
        end
        dims = Array(dims)
        dims.map!{ dim(it) } unless dims.first.is_a? NetCDF::Dim
        var = super(name.to_s, type, dims)
        var.set_fill_value(fill_value, _type: type) if fill_value
        var
      end

      def write_att(name, att_or_values, values = nil)
        if values
          var(name).write_att(att_or_values, values)
        elsif (values = att_or_values).is_a? Numo::NArray
          super(name.to_s, values.class.name.demodulize, values)
        else
          write_att_s(name.to_s, values.to_s)
        end
      end
    end
    prepend self::WithOverrides

    def read_att(name, att_name = nil)
      att_name ? var(name).read_att(att_name) : att(name).read
    end

    def delete_att(name, att_name = nil)
      att_name ? var(name).delete_att(att_name) : att(name).destroy
    end

    def write(name, values, **)
      var(name).write(values, **)
    end

    def read(name, **)
      var(name).read(**)
    end

    def at(name, *)
      var(name).at(*)
    end

    def [](name, *ranges)
      var(name)[*ranges]
    end

    def fill_value(name)
      var(name).fill_value
    end

    def set_fill_value(name, *)
      var(name).set_fill_value(*)
    end

    def dig(name, *indexes)
      return unless (object = vars[name] || atts[name])
      return object.dig(*indexes) unless indexes.empty?
      object
    end

    private :write_att_s
  end
end
