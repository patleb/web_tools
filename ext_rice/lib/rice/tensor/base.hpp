namespace Tensor {
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
    Tensor::Type type = Tensor::Type::Base;

    explicit Base(const Vsize_t & shape):
      shape(shape),
      offsets(offsets_for(shape)),
      size(size_for(shape)),
      rank(shape.size()) {
    }

    Base() = delete;

    Base(const Base & tensor):
      nodata(nullptr),
      data(nullptr),
      type(Tensor::Type::Base) {
      copy_to_base(tensor);
    }

    <%- compile_vars[:numeric_types].each_key do |tensor_type| -%>
    explicit operator <%= tensor_type %> * () const;
    explicit operator <%= tensor_type %> & () const;
    <%- end -%>

    GType nodata_value() const {
      switch (type) {
      <%- compile_vars[:numeric_types].each do |tensor_type, type| -%>
      case Tensor::Type::<%= tensor_type %>: return g_cast(*reinterpret_cast< const <%= type %> * >(nodata));
      <%- end -%>
      default:
        throw RuntimeError("invalid Tensor::Type");
      }
    }

    auto _shape_() const {
      return shape;
    }

    auto & reshape(const Vsize_t & shape) {
      auto total = size_for(shape);
      if (total != size) throw RuntimeError("shape.total[" S(total) "] != size[" S(size) "]");
      this->shape = shape;
      this->offsets = offsets_for(shape);
      this->size = total;
      this->rank = shape.size();
      return *this;
    }

    virtual size_t type_size() const {
      throw RuntimeError("not implemented error");
    }

    protected:

    void copy_to_base(const Base & tensor) {
      this->shape = tensor.shape;
      this->offsets = tensor.offsets;
      this->size = tensor.size;
      this->rank = tensor.rank;
    }

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
      for (ssize_t i = rank - 2; i >= 0; --i) {
        auto & size = shape[i + 1];
        if (size == 0) throw RuntimeError("dimension [" S(i) "] is empty");
        offsets[i] = offsets[i + 1] * size;
      }
      if (shape.front() == 0) throw RuntimeError("first dimension is empty");
      return offsets;
    }

    size_t size_for(const Vsize_t & shape) const {
      return std::ranges::fold_left(shape, 1, std::multiplies());
    }
  };
}
