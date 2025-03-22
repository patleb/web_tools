module NetCDF
  class MissingError < ::StandardError
    def initialize(name)
      super "#{self.class.name.demodulize.titleize} [#{name}]"
    end
  end

  class MissingDimension < MissingError; end
  class MissingAttribute < MissingError; end
  class MissingVariable < MissingError; end

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

      def close
        super
        @dims = @vars = @atts = nil
      end

      def dims
        @dims ||= super.map{ [it.name, it] }.to_hwia
      end

      def vars
        @vars ||= super.map{ [it.name, it] }.to_hwia
      end

      def atts
        @atts ||= super.map{ [it.name, it] }.to_hwia
      end

      def create_dim(name, *)
        @dims = nil
        super(name.to_s, *)
      end

      def create_var(name, type, dims, fill_value: nil)
        @vars = nil
        case type
        when Class
          type = type.name.demodulize if type <= Numo::NArray
        when Numo::NArray
          type = type.class.name.demodulize
        else
          type = type.to_s
        end
        dims = Array(dims)
        unless dims.first.is_a? NetCDF::Dim
          dims = dims.map{ |key| self.dims[key] or raise MissingDimension, key }
        end
        var = super(name.to_s, type, dims)
        var.set_fill_value(fill_value, _type: type) if fill_value
        var
      end

      def write_att(name, values, var: nil)
        if var
          var = vars[var] or raise MissingVariable, var
          @vars = nil
          return var.write_att(name, values)
        end
        @atts = nil
        if values.is_a? Numo::NArray
          super(name.to_s, values.class.name.demodulize, values)
        else
          write_att_s(name.to_s, values.to_s)
        end
      end
    end
    prepend self::WithOverrides

    def read_att(name, var: nil)
      if var
        var = vars[var] or raise MissingVariable, var
        var.read_att(name)
      else
        att = atts[name] or raise MissingAttribute, name
        att.read
      end
    end

    def delete_att(name, var: nil)
      if var
        var = vars[var] or raise MissingVariable, var
        @vars = nil
        var.delete_att(name)
      else
        att = atts[name] or raise MissingAttribute, name
        @atts = nil
        att.destroy
      end
    end

    def write(var, values, ...)
      var = vars[var] or raise MissingVariable, var
      var.write(values, ...)
    end

    def read(var, ...)
      var = vars[var] or raise MissingVariable, var
      var.read(...)
    end

    def fill_value(var)
      var = vars[var] or raise MissingVariable, var
      var.fill_value
    end

    def set_fill_value(var, *)
      var = vars[var] or raise MissingVariable, var
      var.set_fill_value(*)
    end

    def dig(name, *indexes)
      return unless (object = vars[name] || atts[name])
      return object.dig(*indexes) unless indexes.empty?
      object
    end

    private :write_att_s
  end
end
