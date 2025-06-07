namespace Tensor {
  <%- compile_vars[:numeric_types].each do |tensor_type, type| -%>

  class <%= tensor_type %> : public Base {
    public:

    <%= type %> fill_value = <%= %w(float double).include?(type) ? 'Float::NAN' : 0 %>;
    std::valarray< <%= type %> > array;

    <%= tensor_type %>(const <%= tensor_type %> & tensor):
      Base::Base(tensor),
      fill_value(tensor.fill_value),
      array(tensor.array) {
      update_base();
    }

    explicit <%= tensor_type %>(const Vsize_t & shape, const O<%= type %> & fill_value = nil):
      Base::Base(shape),
      fill_value(fill_value.value_or(<%= %w(float double).include?(type) ? 'Float::NAN' : 0 %>)),
      array(this->fill_value, this->size) {
      update_base();
    }

    explicit <%= tensor_type %>(const V<%= type %> & values, const Vsize_t & shape, const O<%= type %> & fill_value = nil):
      Base::Base(shape),
      fill_value(fill_value.value_or(<%= %w(float double).include?(type) ? 'Float::NAN' : 0 %>)),
      array(values.data(), values.size()) {
      if (values.size() != size) throw RuntimeError("values.size[" S(values.size()) "] != shape.total[" S(size) "]");
      update_base();
    }

    static auto from_sql(const std::string & values) {
      // TODO
    }

    auto to_sql() const {
      auto data = reinterpret_cast< <%= type %> * >(this->data);
      size_t dim_i = 0, dim_j;
      size_t dim_n = rank - 1;
      size_t counts[rank];
      std::memcpy(counts, shape.data(), rank * sizeof(size_t));
      std::stringstream sql;
      while (true) {
        while (true) {
          sql << '{';
          if (dim_i == dim_n) break;
          ++dim_i;
        }
        while (true) {
          sql << std::format("{}", *data++);
          if (--counts[dim_i] == 0) break;
          sql << ',';
        }
        while (true) {
          sql << '}';
          if (dim_i == 0) {
            return std::string(sql.str().c_str());
          }
          if (--counts[dim_i - 1] != 0) {
            for (dim_j = dim_i; dim_j <= dim_n; ++dim_j) counts[dim_j] = shape[dim_j];
            sql << ',';
            break;
          }
          --dim_i;
        }
      }
    }

    bool operator==(const Tensor::Base & tensor) const {
      if (type != tensor.type) return false;
      if (shape != tensor.shape) return false;
      return std::equal(&array[0], &array[size - 1], reinterpret_cast< const <%= type %> * >(tensor.data));
    }
    <%- if %w(float double).include? type -%>
    auto operator*(const Tensor::<%= tensor_type %> & tensor) const {
      if (!std::isnan(fill_value)) throw RuntimeError("fill_value must be Float::NAN");
      return <%= tensor_type %>(array * tensor.array, shape, fill_value);
    }
    auto operator*(<%= type %> value) const {
      if (!std::isnan(fill_value)) throw RuntimeError("fill_value must be Float::NAN");
      if (value ==  0.0) return <%= tensor_type %>(std::valarray< <%= type %> >(0.0, size), shape, fill_value);
      if (value ==  1.0) return <%= tensor_type %>(+array, shape, fill_value);
      if (value == -1.0) return <%= tensor_type %>(-array, shape, fill_value);
      return <%= tensor_type %>(array * value, shape, fill_value);
    }
    <%- %w(/ + -).each do |op| -%>
    auto operator<%= op %>(const Tensor::<%= tensor_type %> & tensor) const {
      if (!std::isnan(fill_value)) throw RuntimeError("fill_value must be Float::NAN");
      return <%= tensor_type %>(array <%= op %> tensor.array, shape, fill_value);
    }
    auto operator<%= op %>(<%= type %> value) const {
      if (!std::isnan(fill_value)) throw RuntimeError("fill_value must be Float::NAN");
      return <%= tensor_type %>(array <%= op %> value, shape, fill_value);
    }
    <%- end -%>
    <%- end -%>
    auto & operator[](size_t i)       { return array[i]; }
    auto & operator[](size_t i) const { return array[i]; }
    auto & operator[](const Vsize_t & indexes)       { return array[offset_for(indexes)]; }
    auto & operator[](const Vsize_t & indexes) const { return array[offset_for(indexes)]; }
    auto & first()       { return array[0]; }
    auto & first() const { return array[0]; }
    auto & last()        { return array[size - 1]; }
    auto & last()  const { return array[size - 1]; }

    auto values() const {
      return V<%= type %>(std::begin(array), std::end(array));
    }

    auto slice(const Vsize_t & start = {}, const Vsize_t & count = {}, const Vsize_t & stride = {}) const {
      size_t offset = offset_for(start);
      auto counts = counts_or_ones(count);
      auto strides = counts_or_ones(stride);
      auto slice = std::gslice(offset, counts, strides);
      auto shape = Vsize_t(std::begin(counts), std::end(counts));
      return <%= tensor_type %>(array[slice], shape, fill_value);
    }

    auto & refill_value(<%= type %> fill_value) {
      if (std::isnan(this->fill_value)) {
        if (std::isnan(fill_value)) return *this;
        for (size_t i = 0; auto && value : array) if (std::isnan(value)) array[i] = fill_value;
      } else {
        if (fill_value == this->fill_value) return *this;
        for (size_t i = 0; auto && value : array) if (value == this->fill_value) array[i] = fill_value;
      }
      this->fill_value = fill_value;
      return *this;
    }

    auto & reshape(const Vsize_t & shape) {
      Base::reshape(shape);
      return *this;
    }

    auto & seq(<%= type %> start = 0) {
      std::iota(std::begin(array), std::end(array), start);
      return *this;
    }

    size_t type_size() const override {
      return sizeof(<%= type %>);
    }

    const char * type_name() const override {
      return "<%= tensor_type %>";
    }

    private:

    <%= tensor_type %>(std::valarray< <%= type %> > && array, const Vsize_t & shape, <%= type %> fill_value):
      Base::Base(shape),
      fill_value(fill_value),
      array(array) {
      update_base();
    }

    void update_base() {
      this->nodata = reinterpret_cast< void * >(&fill_value);
      this->data = reinterpret_cast< void * >(&array[0]);
      this->type = Tensor::Type::<%= tensor_type %>;
    }
  };

  inline Base::operator <%= tensor_type %> * () const {
    return dynamic_cast< <%= tensor_type %> * >(const_cast< Base * >(this));
  }

  inline Base::operator <%= tensor_type %> & () const {
    return dynamic_cast< <%= tensor_type %> & >(*const_cast< Base * >(this));
  }
  <%- end -%>
}
