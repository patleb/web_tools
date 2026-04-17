module MatIO
  Var.class_eval do
    prepend Tensor::Readable

    alias_method :dig, :[]

    def numeric?
      type != Type::String
    end
  end
end
