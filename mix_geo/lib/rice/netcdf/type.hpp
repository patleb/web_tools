namespace NetCDF {
  using std::string;
  using std::vector;

  enum class Type {
    <%- template[:netcdf].each do |TENSOR, NC_TYPE| -%>
    TENSOR = NC_TYPE,
    <%- end -%>
    String = NC_CHAR
  };

  class TypeError : public RuntimeError {
    public:

    TypeError(CONTEXT(trace, source)):
      RuntimeError("TypeError", trace, source) {
    }
  };

  inline int type_id(const Tensor::NType & values) {
    switch (values.index()) {
    <%- template[:netcdf].each_value.with_index do |NC_TYPE, I| -%>
    case I: return NC_TYPE;
    <%- end -%>
    case <%= template[:netcdf].size %>: return NC_CHAR;
    default: throw TypeError();
    }
  }

  inline int type_id(std::string_view name) {
    <%- template[:netcdf].each do |TENSOR, NC_TYPE| -%>
    if (name == "<%= @TENSOR %>") return NC_TYPE;
    <%- end -%>
    if (name == "String") return NC_CHAR;
    throw TypeError();
  }

  inline auto type(int id) {
    switch (id) {
    <%- template[:netcdf].each do |TENSOR, NC_TYPE| -%>
    case NC_TYPE: return NetCDF::Type::TENSOR;
    <%- end -%>
    case NC_CHAR: return NetCDF::Type::String;
    }
    throw TypeError();
  }
}
