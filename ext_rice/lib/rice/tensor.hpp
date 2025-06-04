namespace Tensor {
  using std::vector;

  enum class Type {
    <%- compile_vars[:numeric_types].each_key do |tensor_type| -%>
    <%= tensor_type %>,
    <%- end -%>
    Base
  };

  <%- compile_vars[:numeric_types].each_key do |tensor_type| -%>
  class <%= tensor_type %>;
  <%- end -%>

  class Base {
    public:

    Vsize_t shape;
    Vsize_t offsets;
    size_t size;
    size_t rank;
    void * nodata = nullptr;
    void * data = nullptr;

    explicit Base(const Vsize_t & shape):
      shape(shape),
      offsets(offsets_for(shape)),
      size(size_for(shape)),
      rank(shape.size()) {
    }

    <%- compile_vars[:numeric_types].each_key do |tensor_type| -%>
    explicit operator <%= tensor_type %> * () const;
    explicit operator <%= tensor_type %> & () const;
    <%- end -%>

    auto dims() {
      return shape;
    }

    void reshape(const Vsize_t & shape) {
      auto total = size_for(shape);
      if (total != size) throw RuntimeError("shape.total[" S(total) "] != size[" S(size) "]");
      this->shape = shape;
      this->offsets = offsets_for(shape);
      this->size = total;
      this->rank = shape.size();
    }

    virtual size_t type_size() const {
      throw RuntimeError("not implemented error");
    }

    virtual Tensor::Type type_id() const {
      return Tensor::Type::Base;
    }

    virtual const char * type_name() const {
      return "Base";
    }

    protected:

    auto offset_for(const Vsize_t & indexes) const {
      size_t offset = 0;
      if (!indexes.empty()) {
        if (indexes.size() != rank) throw RuntimeError("indexes.size[" S(indexes.size()) "] != rank[" S(rank) "]");
        for (size_t i = 0; auto && index : indexes) {
          if (index >= shape[i]) throw RuntimeError("index[" S(index) "] >= shape[" S(shape[i]) "]");
          offset += index * offsets[i++];
        }
      }
      return offset;
    }

    auto counts_or_ones(const Vsize_t & count) const {
      auto counts = count.empty() ? std::valarray< size_t >(1, rank) : std::valarray< size_t >(count.data(), count.size());
      if (counts.size() != rank) throw RuntimeError("count.size[" S(counts.size()) "] != rank[" S(rank) "]");
      return counts;
    }

    private:

    Vsize_t offsets_for(const Vsize_t & shape) const {
      auto rank = shape.size();
      if (rank == 0) throw RuntimeError("at least one dimension must be defined");
      Vsize_t offsets(rank, 1);
      for (size_t i = 1; i < rank; ++i) {
        auto & size = shape[i - 1];
        if (size == 0) throw RuntimeError("dimension [" S(i) "] is empty");
        offsets[i] = offsets[i - 1] * size;
      }
      if (shape.back() == 0) throw RuntimeError("last dimension is empty");
      return offsets;
    }

    size_t size_for(const Vsize_t & shape) const {
      return std::ranges::fold_left(shape, 1, std::multiplies());
    }
  };
  <%- compile_vars[:numeric_types].each do |tensor_type, type| -%>

  class <%= tensor_type %> : public Base {
    public:

    <%= type %> fill_value;
    std::valarray< <%= type %> > array;

    explicit <%= tensor_type %>(const Vsize_t & shape, std::optional< <%= type %> > fill_value = std::nullopt):
      Base::Base(shape),
      fill_value(fill_value.value_or(static_cast< <%= type %> >(C::Nil))),
      array(this->fill_value, this->size) {
      update_base_pointers();
    }

    explicit <%= tensor_type %>(const V<%= type %> & values, const Vsize_t & shape, std::optional< <%= type %> > fill_value = std::nullopt):
      Base::Base(shape),
      fill_value(fill_value.value_or(static_cast< <%= type %> >(C::Nil))),
      array(values.data(), values.size()) {
      if (values.size() != size) throw RuntimeError("values.size[" S(values.size()) "] != shape.total[" S(size) "]");
      update_base_pointers();
    }

    auto & operator[](size_t i) {
      return array[i];
    }

    auto & operator[](size_t i) const {
      return array[i];
    }

    auto & operator[](const Vsize_t & indexes) {
      return array[offset_for(indexes)];
    }

    auto & operator[](const Vsize_t & indexes) const {
      return array[offset_for(indexes)];
    }

    auto values() const {
      return V<%= type %>(std::begin(array), std::end(array));
    }

    auto slice(const Vsize_t & start = {}, const Vsize_t & count = {}, const Vsize_t & stride = {}) const {
      size_t offset = offset_for(start);
      auto counts = counts_or_ones(count);
      auto strides = counts_or_ones(stride);
      std::valarray< <%= type %> > view = array[std::gslice(offset, counts, strides)];
      return <%= tensor_type %>(view, Vsize_t(std::begin(counts), std::end(counts)), fill_value);
    }

    auto & sequence(<%= type %> start = 0) {
      std::iota(std::begin(array), std::end(array), start);
      return *this;
    }

    auto to_sql() {
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

    size_t type_size() const override {
      return sizeof(<%= type %>);
    }

    Tensor::Type type_id() const override {
      return Tensor::Type::<%= tensor_type %>;
    }

    const char * type_name() const override {
      return "<%= tensor_type %>";
    }

    private:

    <%= tensor_type %>(const std::valarray< <%= type %> > & array, const Vsize_t & shape, <%= type %> fill_value):
      Base::Base(shape),
      fill_value(fill_value),
      array(array) {
      update_base_pointers();
    }

    void update_base_pointers() {
      this->nodata = reinterpret_cast< void * >(&this->fill_value);
      this->data = reinterpret_cast< void * >(&this->array[0]);
    }
  };
  <%- end -%>
  <%- compile_vars[:numeric_types].each_key do |tensor_type| -%>

  inline Base::operator <%= tensor_type %> * () const {
    return dynamic_cast< <%= tensor_type %> * >(const_cast< Base * >(this));
  }

  inline Base::operator <%= tensor_type %> & () const {
    return dynamic_cast< <%= tensor_type %> & >(*const_cast< Base * >(this));
  }
  <%- end -%>

  using NType = std::variant< <%= compile_vars[:numeric_types].keys.join(', ') %>, Vstring >;
}
