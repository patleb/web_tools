module Tensor
  def self.types
    @@types ||= ExtRice.config.compile_vars[:numeric_types].keys.map{ |name| Tensor::Type.const_get(name) }
  end

  ExtRice.config.compile_vars[:numeric_types].each_key do |name|
    const_get(name).class_eval do
      module self::WithOverrides
        def initialize(*values, **)
          super(values, **)
        end

        def [](*indexes)
          super(indexes)
        end

        def []=(*indexes, value)
          super(indexes, value)
        end

        def seq(start = 0)
          super
        end
      end
      prepend self::WithOverrides

      def self.[](*values)

      end

      def type
        Tensor.types[type_id]
      end
    end
  end
end
