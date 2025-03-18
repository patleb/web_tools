module NetCDF
  File.class_eval do
    def self.read(path, **)
      file = new(path, **)
      yield file
    ensure
      file&.close
    end

    def self.write(path, **)
      file = new(path, 'w', **)
      yield file
    ensure
      file&.close
    end

    def self.append(path, **)
      file = new(path, 'a', **)
      yield file
    ensure
      file&.close
    end

    module self::WithOverrides
      def initialize(path, mode = 'r', classic: false, share: false)
        super(path.to_s, mode, classic, share)
      end

      def open(path, mode = 'r', classic: false, share: false)
        super(path.to_s, mode, classic, share)
      end

      def close
        super
        @dims = @vars = @atts = nil
      end

      def reload
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
        super(name.to_s, *)
      end

      def create_var(name, type, dims)
        if type.is_a?(Class) && type <= Numo::NArray
          type = type.name.demodulize
        elsif type.is_a? Numo::NArray
          type = type.class.name.demodulize
        end
        unless dims.first.is_a? NetCDF::Dim
          dims = dims.map{ |key| self.dims[key] || raise("missing dimension [#{key}]") }
        end
        super(name.to_s, type, dims)
      end

      def write_att(name, values, var: nil)
        if var
          var = vars[var] || raise("missing variable [#{var}]")
          var.write_att(name, values)
        elsif values.is_a? Numo::NArray
          super(name.to_s, values.class.name.demodulize, values)
        else
          write_att_s(name.to_s, values.to_s)
        end
      end
    end
    prepend self::WithOverrides

    def write(var, values, *, **)
      var = vars[var] || raise("missing variable [#{var}]")
      var.write(values, *, **)
    end

    def delete_att(name, var: nil)
      if var
        var = vars[var] || raise("missing variable [#{var}]")
        var.delete_att(name)
      else
        att = atts[name] || raise("missing attribute [#{name}]")
        att.destroy
      end
    end

    private :write_att_s
  end
end
