namespace Tensor {
  using NType = std::variant< <%= compile_vars[:numeric_types].keys.join(', ') %>, Vstring >;

  Tensor::NType build(Tensor::Type type, const Vsize_t & shape, const GType & fill_value = null) {
    switch (type) {
    <%- compile_vars[:numeric_types].each do |tensor_type, type| -%>
    case Tensor::Type::<%= tensor_type %>: return Tensor::<%= tensor_type %>(shape, g_cast< <%= type %> >(fill_value));
    <%- end -%>
    default:
      throw RuntimeError("invalid Tensor::Type");
    }
  }

  Tensor::NType cast(Tensor::Base & tensor, Tensor::Type type) {
    switch (type) {
    <%- compile_vars[:numeric_types].each_key do |tensor_type| -%>
    case Tensor::Type::<%= tensor_type %>: return dynamic_cast< Tensor::<%= tensor_type %> & >(tensor);
    <%- end -%>
    default:
      throw RuntimeError("invalid Tensor::Type");
    }
  }

  Tensor::Base & cast(Tensor::NType & tensor) {
    switch (tensor.index()) {
    <%- compile_vars[:numeric_types].size.times do |i| -%>
    case <%= i %>: return std::get< <%= i %> >(tensor);
    <%- end -%>
    default:
      throw RuntimeError("invalid Tensor::NType");
    }
  }

  Tensor::Type type(const Tensor::NType & tensor) {
    switch (tensor.index()) {
    <%- compile_vars[:numeric_types].each_key.with_index do |tensor_type, i| -%>
    case <%= i %>: return Tensor::Type::<%= tensor_type %>;
    <%- end -%>
    default:
      throw RuntimeError("invalid Tensor::NType");
    }
  }
}
