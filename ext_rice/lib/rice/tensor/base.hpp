namespace Tensor {
  enum class Type {
    <%- template[:numeric].each_key do |TENSOR| -%>
    TENSOR,
    <%- end -%>
    Base
  };

  <%- template[:numeric].each_key do |TENSOR| -%>
  class TENSOR;
  <%- end -%>

  class Base {
    public:

    const size_t size;
    Vsize_t shape;
    Vsize_t offsets;
    size_t rank;
    void * nodata = nullptr;
    void * _data_ = nullptr;
    Tensor::Type type = Tensor::Type::Base;

    explicit Base(const Vsize_t & shape):
      size(size_for(shape)),
      shape(shape),
      offsets(offsets_for(shape)),
      rank(shape.size()) {
    }

    Base() = delete;

    Base(const Base & tensor):
      size(tensor.size),
      shape(tensor.shape),
      offsets(tensor.offsets),
      rank(tensor.rank) {
    }

    Base & operator=(const Base & tensor) = delete;

    <%- template[:numeric].each_key do |TENSOR| -%>
    explicit operator TENSOR * () const;
    explicit operator TENSOR & () const;
    <%- end -%>

    static size_t size_for(const Vsize_t & shape) {
      return std::ranges::fold_left(shape, 1, std::multiplies());
    }

    GType nodata_value() const {
      switch (type) {
      <%- template[:numeric].each do |TENSOR, T| -%>
      case Tensor::Type::TENSOR: return g_cast(*reinterpret_cast< const T * >(nodata));
      <%- end -%>
      default:
        throw RuntimeError("invalid Tensor::Type");
      }
    }

    auto _shape_() const {
      return shape;
    }

    auto _offsets_() const {
      return offsets;
    }

    auto & reshape(const Vsize_t & shape) {
      auto total = size_for(shape);
      if (total != size) throw RuntimeError("shape.total[" S(total) "] != size[" S(size) "]");
      this->shape = shape;
      this->offsets = offsets_for(shape);
      this->rank = shape.size();
      return *this;
    }

    auto data()       { return _data_; }
    auto data() const { return _data_; }

    virtual size_t type_size() const {
      throw RuntimeError("not implemented error");
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
      for (ssize_t i = rank - 2; i >= 0; --i) {
        auto & size = shape[i + 1];
        if (size == 0) throw RuntimeError("dimension [" S(i) "] is empty");
        offsets[i] = offsets[i + 1] * size;
      }
      if (shape.front() == 0) throw RuntimeError("first dimension is empty");
      return offsets;
    }
  };
}
