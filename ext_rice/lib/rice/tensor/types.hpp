namespace Tensor {
  <%- template[:numeric].each do |TENSOR, T| -%>

  class TENSOR : public Base {
    public:

    T fill_value = <%= %w(float double).include?(@T) ? 'Float::nan' : 0 %>;
    std::valarray< T > array;

    explicit TENSOR(const Vsize_t & shape, const O-T- & fill_value = nil):
      Base::Base(shape),
      fill_value(fill_value.value_or(<%= %w(float double).include?(@T) ? 'Float::nan' : 0 %>)),
      array(this->fill_value, this->size) {
      sync_refs();
    }

    explicit TENSOR(const V-T- & values, const Vsize_t & shape, const O-T- & fill_value = nil):
      Base::Base(shape),
      fill_value(fill_value.value_or(<%= %w(float double).include?(@T) ? 'Float::nan' : 0 %>)),
      array(values.data(), values.size()) {
      if (values.size() != size) throw RuntimeError("values.size[" S(values.size()) "] != shape.total[" S(size) "]");
      sync_refs();
    }

    TENSOR() = delete;

    TENSOR(const TENSOR & tensor):
      Base::Base(tensor),
      fill_value(tensor.fill_value),
      array(tensor.array) {
      sync_refs();
    }

    TENSOR & operator=(const TENSOR & tensor) = delete;

    static auto from_sql(const std::string & values, const Vsize_t & shape, const GType & fill_value = none) {
      bool new_value = true;
      char buffer[24 + 1]; // double + '\0'
      TENSOR tensor(shape, g_cast< T >(fill_value));
      auto data = reinterpret_cast< T * >(tensor.data);
      for (size_t i = 0; auto && c : values) {
        switch (c) {
        case '{': case ' ':
          break;
        case ',': case '}':
          if (new_value) {
            new_value = false;
            buffer[i] = '\0';
            *(data++) = (std::strncmp(buffer, "NULL", 4) == 0) ? tensor.fill_value : parse_number(buffer);
            i = 0;
          }
          break;
        default:
          new_value = true;
          buffer[i++] = c;
        }
      }
      return tensor;
    }

    static T parse_number(char * buffer) {
    <%- case @T -%>
    <%- when 'float' -%>
      return static_cast< T >(std::atof(buffer));
    <%- when 'double' -%>
      return std::atof(buffer);
    <%- when 'uint32_t' -%>
      return static_cast< T >(std::strtoul(buffer, nullptr, 10));
    <%- when 'int64_t2' -%>
      return std::atoll(buffer);
    <%- when 'uint64_t2' -%>
      return std::strtoull(buffer, nullptr, 10);
    <%- else -%>
      return static_cast< T >(std::atoi(buffer));
    <%- end -%>
    }
    <%- if %w(float double).include? @T -%>
    <%- %w(* / + -).each do |OP| -%>

    auto operator-OP-(const Tensor::TENSOR & tensor) const {
      if (!std::isnan(fill_value)) throw RuntimeError("fill_value must be Float::nan");
      return TENSOR(array -OP- tensor.array, shape, fill_value);
    }

    auto operator-OP-(T value) const {
      if (!std::isnan(fill_value)) throw RuntimeError("fill_value must be Float::nan");
      return TENSOR(array -OP- value, shape, fill_value);
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
    auto begin()         { return std::begin(array); }
    auto begin()   const { return std::begin(array); }
    auto end()           { return std::end(array); }
    auto end()     const { return std::end(array); }

    // NOTE won't consider NaN --> use #to_sql
    bool operator==(const Tensor::Base & tensor) const {
      if (type != tensor.type) return false;
      if (shape != tensor.shape) return false;
      return std::equal(begin(), end(), dynamic_cast< const TENSOR & >(tensor).begin());
    }

    auto values() const {
      return V-T-(begin(), end());
    }

    auto slice(const Vsize_t & start = {}, const Vsize_t & count = {}, const Vsize_t & stride = {}) const {
      size_t offset = offset_for(start);
      auto counts = counts_or_ones(count);
      auto strides = counts_or_ones(stride);
      auto slice = std::gslice(offset, counts, strides);
      auto shape = Vsize_t(std::begin(counts), std::end(counts));
      return TENSOR(array[slice], shape, fill_value);
    }

    auto & refill_value(T fill_value) {
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

    auto & seq(const O-T- & start = nil) {
      std::iota(begin(), end(), start.value_or(0));
      return *this;
    }

    size_t type_size() const override {
      return sizeof(T);
    }

    auto to_sql(const Ostring & before = nil, const Ostring & after = nil, Obool nulls = nil) const {
      auto data = reinterpret_cast< T * >(this->data);
      auto as_null = nulls.value_or(false);
      auto isnan_nodata = std::isnan(fill_value);
      size_t dim_i = 0, dim_j;
      size_t dim_n = rank - 1;
      size_t counts[rank];
      std::memcpy(counts, shape.data(), rank * sizeof(size_t));
      std::stringstream sql;
      if (before) sql << before.value();
      while (true) {
        while (true) {
          sql << '{';
          if (dim_i == dim_n) break;
          ++dim_i;
        }
        while (true) {
          auto value = *data++;
          if (as_null)
            if (isnan_nodata) sql << (std::isnan(value)   ? "NULL" : std::format("{}", value));
            else              sql << (value == fill_value ? "NULL" : std::format("{}", value));
          else                sql << std::format("{}", value);
          if (--counts[dim_i] == 0) break;
          sql << ',';
        }
        while (true) {
          sql << '}';
          if (dim_i == 0) {
            if (after) sql << after.value();
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

    private:

    TENSOR(std::valarray< T > && array, const Vsize_t & shape, T fill_value):
      Base::Base(shape),
      fill_value(fill_value),
      array(array) {
      sync_refs();
    }

    void sync_refs() {
      this->nodata = reinterpret_cast< void * >(&fill_value);
      this->data = reinterpret_cast< void * >(&array[0]);
      this->type = Tensor::Type::TENSOR;
    }
  };

  inline Base::operator TENSOR * () const {
    return dynamic_cast< TENSOR * >(const_cast< Base * >(this));
  }

  inline Base::operator TENSOR & () const {
    return dynamic_cast< TENSOR & >(*const_cast< Base * >(this));
  }
  <%- end -%>
}
