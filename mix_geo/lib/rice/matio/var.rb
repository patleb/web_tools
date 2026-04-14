module MatIO
  Var.class_eval do
    prepend Tensor::Readable

    def numeric?
      type != Type::String
    end
  end
end
