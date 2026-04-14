namespace MatIO {
  class Var : public Base {
    public:

    string name;
    string path;
    matvar_t * var = NULL;

    using Base::Base;

    Var() = default;

    Var(mat_t * file, const string & name, const string & path, matvar_t * var):
      Base(file),
      name(name),
      path(path),
      var(var) {
    }

    auto type()       const { return MatIO::type(type_id()); }
    auto dims_count() const { return var->rank; }
    auto bytes()      const { return Mat_VarGetSize(var); }
    auto size()       const { return Tensor::Base::size_for(shape()); }

    Vsize_t shape() const {
      auto shape = Vsize_t(var->dims, var->dims + dims_count());
      return type_id() != MAT_C_CHAR ? shape : Vsize_t{ Tensor::Base::size_for(shape) };
    }

    Tensor::NType read(const Vsize_t & start = {}, const Vsize_t & count = {}, const Vsize_t & stride = {}) const {
      if (var->isComplex) throw NotSupportedError();
      switch (type_id()) {
      <%- template[:matio].each do |TENSOR, MAT_C_TYPE| -%>
      case MAT_C_TYPE: {
        size_t dims_count = this->dims_count();
        Vint starts = start.empty() ? Vint(dims_count, 0) : vector_cast< size_t, int >(start);
        Vint counts = count.empty() ? Vint(dims_count, 1) : vector_cast< size_t, int >(count);
        Vint strides = stride.empty() ? Vint(dims_count, 1) : vector_cast< size_t, int >(stride);
        if (starts.size() != dims_count) throw ArgsError();
        if (counts.size() != dims_count) throw ArgsError();
        if (strides.size() != dims_count) throw ArgsError();
        auto shape = vector_cast< int, size_t >(counts);
        std::reverse(shape.begin(), shape.end());
        Tensor::TENSOR values(shape);
        check_status( Mat_VarReadData(file, var, values.Base::data(), starts.data(), strides.data(), counts.data()) );
        return values.reverse_shape();
      }
      <%- end -%>
      case MAT_C_CHAR: {
        if (start.size() > 1) throw ArgsError();
        if (count.size() > 1) throw ArgsError();
        int max_size = this->shape()[0];
        int start_0 = start.empty() ? 0 : static_cast< int >(start[0]);
        int count_0 = count.empty() ? max_size : static_cast< int >(count[0]);
        check_status( Mat_VarReadDataAll(file, var) );
        auto value = string_cast< char16_t, char >(reinterpret_cast< const char * >(var->data), bytes());
        return Vstring{ value.substr(start_0, count_0) };
      }
      default:
        throw TypeError();
      }
    }

    private:

    matio_classes type_id() const { return var->class_type; }
  };
}
