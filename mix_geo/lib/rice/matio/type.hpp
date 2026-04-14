namespace MatIO {
  using std::string;
  using std::vector;

  enum class Type {
    <%- template[:matio].each do |TENSOR, MAT_C_TYPE| -%>
    TENSOR = MAT_C_TYPE,
    <%- end -%>
    String = MAT_C_CHAR
  };

  inline matio_classes type_id(const Tensor::NType & values) {
    switch (values.index()) {
    <%- template[:matio].each_value.with_index do |MAT_C_TYPE, I| -%>
    case I: return MAT_C_TYPE;
    <%- end -%>
    default: throw TypeError();
    }
  }

  inline matio_classes type_id(std::string_view name) {
    <%- template[:matio].each do |TENSOR, MAT_C_TYPE| -%>
    if (name == "<%= @TENSOR %>") return MAT_C_TYPE;
    <%- end -%>
    if (name == "String") return MAT_C_CHAR;
    throw TypeError();
  }

  inline Type type(matio_classes id) {
    switch (id) {
    <%- template[:matio].each do |TENSOR, MAT_C_TYPE| -%>
    case MAT_C_TYPE: return MatIO::Type::TENSOR;
    <%- end -%>
    case MAT_C_CHAR: return MatIO::Type::String;
    }
    throw TypeError();
  }
}
