namespace Tensor {
  <%- template[:numeric].each do |TENSOR, T| -%>

  class TENSOR : public Base {
    public:

    class View {
      public:

      const size_t size;
      std::gslice_array< T > slice;

      View() = delete;

      View(const std::gslice_array< T > & slice, const Vsize_t & shape):
        size(Base::size_for(shape)),
        slice(slice) {
      }

      void operator=(const T & value) const {
        this->slice = value;
      }
      void operator=(const TENSOR & tensor) const {
        if (size != tensor.size) throw RuntimeError("size[" S(size) "] != tensor.size[" S(tensor.size) "]");
        this->slice = tensor.array;
      }
      auto & operator=(const View & view) const {
        if (size != view.size) throw RuntimeError("size[" S(size) "] != view.size[" S(view.size) "]");
        this->slice = view.slice;
        return *this;
      }
      <%- %w(+ - * /).each do |OP| -%>
      void operator-OP-=(const TENSOR & tensor) const {
        if (size != tensor.size) throw RuntimeError("size[" S(size) "] != tensor.size[" S(tensor.size) "]");
        this->slice OP= tensor.array;
      }
      <%- end -%>
    };

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

    <%- %w(+ - * /).each do |OP| -%>
    TENSOR operator-OP-(T value) const {
      return TENSOR(array OP value, shape, fill_value);
    }
    TENSOR operator-OP-(const TENSOR & tensor) const {
      if (size != tensor.size) throw RuntimeError("size[" S(size) "] != tensor.size[" S(tensor.size) "]");
      return TENSOR(array OP tensor.array, shape, fill_value);
    }
    <%- end -%>

    auto & operator()(size_t y, size_t x)       { return array[y * offsets[0] + x]; }
    auto & operator()(size_t y, size_t x) const { return array[y * offsets[0] + x]; }
    auto & operator[](size_t i)       { return array[i]; }
    auto & operator[](size_t i) const { return array[i]; }
    auto & operator[](const Vsize_t & indexes)       { return array[offset_for(indexes)]; }
    auto & operator[](const Vsize_t & indexes) const { return array[offset_for(indexes)]; }
    auto & front()       { return array[0]; }
    auto & front() const { return array[0]; }
    auto & back()        { return array[size - 1]; }
    auto & back()  const { return array[size - 1]; }
    auto begin()         { return std::begin(array); }
    auto begin()   const { return std::begin(array); }
    auto end()           { return std::end(array); }
    auto end()     const { return std::end(array); }
    auto data()          { return reinterpret_cast< T * >(_data_); }
    auto data()    const { return reinterpret_cast< const T * >(_data_); }
    auto values()  const { return V-T-(begin(), end()); }

    // NOTE won't consider NaN --> use #to_sql
    bool operator==(const Tensor::Base & tensor) const {
      if (type != tensor.type) return false;
      if (shape != tensor.shape) return false;
      return std::equal(begin(), end(), dynamic_cast< const TENSOR & >(tensor).begin());
    }

    TENSOR::View slice(const Vsize_t & start = {}, const Vsize_t & count = {}, const Vsize_t & stride = {}) {
      size_t offset = offset_for(start);
      auto counts = counts_or_ones(count);
      auto strides = counts_or_ones(stride);
      auto slice = std::gslice(offset, counts, strides);
      auto shape = Vsize_t(std::begin(counts), std::end(counts));
      return View(std::gslice_array< T >(array[slice]), shape);
    }

    TENSOR slice(const Vsize_t & start = {}, const Vsize_t & count = {}, const Vsize_t & stride = {}) const {
      size_t offset = offset_for(start);
      auto counts = counts_or_ones(count);
      auto strides = counts_or_ones(stride);
      auto slice = std::gslice(offset, counts, strides);
      auto shape = Vsize_t(std::begin(counts), std::end(counts));
      return TENSOR(array[slice], shape, fill_value);
    }

    TENSOR & refill_value(T fill_value) {
      if (std::isnan(this->fill_value)) {
        if (std::isnan(fill_value)) return *this;
        for (size_t i = 0; auto && value : array) if (std::isnan(value)) array[i++] = fill_value;
      } else {
        if (fill_value == this->fill_value) return *this;
        for (size_t i = 0; auto && value : array) if (value == this->fill_value) array[i++] = fill_value;
      }
      this->fill_value = fill_value;
      return *this;
    }

    TENSOR & reshape(const Vsize_t & shape) {
      Base::reshape(shape);
      return *this;
    }

    TENSOR & seq(const O-T- & start = nil) {
      std::iota(begin(), end(), start.value_or(0));
      return *this;
    }

    size_t type_size() const override {
      return sizeof(T);
    }

    static TENSOR from_sql(const std::string & values, const Vsize_t & shape, const GType & fill_value = none) {
      if (values.front() != '{' || values.back() != '}' ) throw RuntimeError("malformed values string");
      bool new_value = false;
      char buffer[24 + 1]; // double + '\0'
      TENSOR tensor(shape, g_cast< T >(fill_value));
      auto data = tensor.data();
      for (size_t i = 0; auto && c : values) {
        switch (c) {
        case '{': case ' ':
          break;
        case ',': case '}':
          if (new_value) {
            new_value = false;
            buffer[i] = '\0';
            bool null = (buffer[0] == 'N' && buffer[1] == 'U');
            if (null) *(data++) = tensor.fill_value;
            <%- case @T -%>
            <%- when 'float' -%>
            else *(data++) = static_cast< T >(std::atof(buffer));
            <%- when 'double' -%>
            else *(data++) = std::atof(buffer);
            <%- when 'uint32_t' -%>
            else *(data++) = static_cast< T >(std::strtoul(buffer, nullptr, 10));
            <%- when 'int64_t2' -%>
            else *(data++) = std::atoll(buffer);
            <%- when 'uint64_t2' -%>
            else *(data++) = std::strtoull(buffer, nullptr, 10);
            <%- else -%>
            else *(data++) = static_cast< T >(std::atoi(buffer));
            <%- end -%>
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

    std::string to_sql(const Ostring & before = nil, const Ostring & after = nil, Obool nulls = nil) const {
      auto data = this->data();
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

    std::string to_string(Osize_t limit = nil) const {
      std::stringstream stream;
      stream << "[";
      std::ranges::for_each(shape, [&stream, first = true](auto size) mutable {
        if (!first) stream << ",";
        else first = false;
        stream << size;
      });
      stream << "]";
      stream << to_sql();
      auto string = std::string(stream.str().c_str());
      if (!limit) return string;
      auto _limit_ = limit.value();
      if (string.size() <= _limit_) return string;
      return string.substr(0, _limit_) + "...";
    }

    static TENSOR atan2(const TENSOR & y, const TENSOR & x) {
      if (y.size != x.size) throw RuntimeError("y.size[" S(y.size) "] != x.size[" S(x.size) "]");
      return TENSOR(std::atan2(y.array, x.array), y.shape, y.fill_value);
    }

    TENSOR abs() const {
    <%- if @T.start_with? 'u' -%>
      return TENSOR(*this);
    <%- else -%>
      return TENSOR(std::abs(array), shape, fill_value);
    <%- end -%>
    }

    TENSOR pow(T exp) const {
      return TENSOR(std::pow(array, std::valarray< T >(exp, size)), shape, fill_value);
    }
    <%- %w(exp log log10 sqrt sin cos tan asin acos atan sinh cosh tanh).each do |F| -%>

    TENSOR F() const {
      return TENSOR(std::F(array), shape, fill_value);
    }
    <%- end -%>

    private:

    TENSOR(std::valarray< T > && array, const Vsize_t & shape, T fill_value):
      Base::Base(shape),
      fill_value(fill_value),
      array(array) {
      sync_refs();
    }

    void sync_refs() {
      this->nodata = reinterpret_cast< void * >(&fill_value);
      this->_data_ = reinterpret_cast< void * >(&array[0]);
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
