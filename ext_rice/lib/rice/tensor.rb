module Tensor
  def self.types
    @@types ||= ExtRice.config.compile_vars[:numeric_types].keys.map{ |name| Tensor::Type.const_get(name) }
  end

  ExtRice.config.compile_vars[:numeric_types].each_key do |name|
    const_get(name).class_eval do
      module self::WithOverrides
        def initialize(*values, **options)
          values = values.first if values.first.is_a? Array
          super(values, **options)
        end

        def shape
          super.to_a
        end

        def [](*indexes)
          super(indexes)
        end

        def []=(*indexes, value)
          super(indexes, value)
        end

        def reshape(*shape)
          shape = shape.first if shape.first.is_a? Array
          shape = self.shape.select_map.with_index do |all, i|
            case (count = shape[i])
            when false then next
            when true  then all
            else count
            end
          end
          super
        end

        def seq(start = 0)
          super
        end
      end
      prepend self::WithOverrides

      def self.[](*values)
        values = values.first.to_a if values.first.is_a? Range
        new(values, shape: [values.size])
      end

      def to_a
        values.to_a
      end
    end
  end
end
