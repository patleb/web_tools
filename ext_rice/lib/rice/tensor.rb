module Tensor
  def self.types
    @@types ||= ExtRice.config.compile_vars[:numeric_types].keys.map{ |name| Tensor::Type.const_get(name) }
  end

  ExtRice.config.compile_vars[:numeric_types].each_key do |name|
    const_get(name).class_eval do
      def type
        Tensor.types[type_id]
      end
    end
  end
end
