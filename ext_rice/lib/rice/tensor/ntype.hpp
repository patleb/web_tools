namespace Tensor {
  using NType = std::variant< <%= template[:numeric_types].keys.join(', ') %>, Vstring >;

  Tensor::NType build(Tensor::Type type, const Vsize_t & shape, const GType & fill_value = none) {
    switch (type) {
    <%- template[:numeric_types].each do |TENSOR, T| -%>
    case Tensor::Type::TENSOR: return Tensor::TENSOR(shape, g_cast< T >(fill_value));
    <%- end -%>
    default:
      throw RuntimeError("invalid Tensor::Type");
    }
  }

  Tensor::NType cast(Tensor::Base & tensor, Tensor::Type type) {
    switch (type) {
    <%- template[:numeric_types].each_key do |TENSOR| -%>
    case Tensor::Type::TENSOR: return dynamic_cast< Tensor::TENSOR & >(tensor);
    <%- end -%>
    default:
      throw RuntimeError("invalid Tensor::Type");
    }
  }

  Tensor::Base & cast(Tensor::NType & tensor) {
    switch (tensor.index()) {
    <%- template[:numeric_types].size.times do |I| -%>
    case I: return std::get< I >(tensor);
    <%- end -%>
    default:
      throw RuntimeError("invalid Tensor::NType");
    }
  }

  Tensor::Type type(const Tensor::NType & tensor) {
    switch (tensor.index()) {
    <%- template[:numeric_types].each_key.with_index do |TENSOR, I| -%>
    case I: return Tensor::Type::TENSOR;
    <%- end -%>
    default:
      throw RuntimeError("invalid Tensor::NType");
    }
  }
}
