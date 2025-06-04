namespace NetCDF {
  using std::string;
  using std::vector;

  enum class Type {
    <%- compile_vars[:netcdf].each do |tensor_type, nc_type| -%>
    <%= tensor_type %> = <%= nc_type %>,
    <%- end -%>
    String = NC_CHAR
  };

  class TypeError : public RuntimeError {
    public:

    TypeError(CONTEXT(trace, source)):
      RuntimeError("TypeError", trace, source) {
    }
  };

  int type_id(const Tensor::NType & values) {
    switch (values.index()) {
    <%- compile_vars[:netcdf].each_value.with_index do |nc_type, i| -%>
    case <%= i %>: return <%= nc_type %>;
    <%- end -%>
    case <%= compile_vars[:netcdf].size %>: return NC_CHAR;
    default: throw TypeError();
    }
  }

  int type_id(std::string_view name) {
    <%- compile_vars[:netcdf].each do |tensor_type, nc_type| -%>
    if (name == "<%= tensor_type %>") return <%= nc_type %>;
    <%- end -%>
    if (name == "String") return NC_CHAR;
    throw TypeError();
  }

  auto type(int id) {
    switch (id) {
    <%- compile_vars[:netcdf].each do |tensor_type, nc_type| -%>
    if (name == "<%= tensor_type %>") return ;
    case <%= nc_type %>: return Type::<%= tensor_type %>;
    <%- end -%>
    case NC_CHAR: return Type::String;
    }
    throw TypeError();
  }
}
