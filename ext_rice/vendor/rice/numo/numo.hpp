/*!
 * Numo.hpp v0.2.0
 * https://github.com/ankane/numo.hpp
 * BSD-2-Clause License
 */

#pragma once

#include <rice/rice.hpp>
#include <numo/narray.h>

namespace Numo {
  enum class Type {
  <%- compile_vars[:numo_types].each do |numo_type| -%>
    <%= numo_type %>,
  <%- end -%>
  };

  <%- compile_vars[:numeric_types].each_key do |numo_type| -%>
  class <%= numo_type %>;
  <%- end -%>

  class NArray {
    public:

    NArray(VALUE v) {
      construct_value(dtype(), v);
    }

    NArray(Rice::Object o) {
      construct_value(dtype(), o.value());
    }

    <%- compile_vars[:numeric_types].each_key do |numo_type| -%>
    explicit operator <%= numo_type %> * () const;
    explicit operator <%= numo_type %> & () const;
    <%- end -%>

    VALUE value() const {
      return _value;
    }

    size_t ndim() const {
      return RNARRAY_NDIM(_value);
    }

    auto shape() const {
      size_t * shape = RNARRAY_SHAPE(_value);
      return std::vector< size_t >(shape, shape + ndim());
    }

    size_t size() const {
      return RNARRAY_SIZE(_value);
    }

    bool is_contiguous() const {
      return nary_check_contiguous(_value) == Qtrue;
    }

    operator Rice::Object() const {
      return Rice::Object(_value);
    }

    virtual size_t type_size() const {
      throw RuntimeError("not implemented error");
    }

    virtual Numo::Type type_id() const {
      return Numo::Type::NArray;
    }

    virtual const char * type_name() const {
      return "NArray";
    }

    const void * read_ptr() {
      if (!is_contiguous()) {
        this->_value = nary_dup(_value);
      }
      return nary_get_pointer_for_read(_value) + nary_get_offset(_value);
    }

    void * write_ptr() {
      return nary_get_pointer_for_write(_value);
    }

    protected:

    NArray() { }

    void construct_value(VALUE dtype, VALUE v) {
      this->_value = rb_funcall(dtype, rb_intern("cast"), 1, v);
    }

    void construct_shape(VALUE dtype, std::initializer_list< size_t > shape) {
      // rb_narray_new doesn't modify shape, but not marked as const
      this->_value = rb_narray_new(dtype, shape.size(), const_cast<size_t*>(shape.begin()));
    }

    void construct_shape(VALUE dtype, std::vector< size_t > shape) {
      this->_value = rb_narray_new(dtype, shape.size(), shape.data());
    }

    VALUE _value;

    private:

    virtual VALUE dtype() const {
      return numo_cNArray;
    }
  };
  <%- compile_vars[:numeric_types].merge('RObject' => 'VALUE').each do |numo_type, type| -%>

  class <%= numo_type %> : public NArray {
    public:

    <%= numo_type %>(VALUE v) {
      construct_value(dtype(), v);
    }

    <%= numo_type %>(Rice::Object o) {
      construct_value(dtype(), o.value());
    }

    explicit <%= numo_type %>(std::initializer_list< size_t > shape) {
      construct_shape(dtype(), shape);
    }

    explicit <%= numo_type %>(std::vector< size_t > shape) {
      construct_shape(dtype(), shape);
    }
  <%- if type != 'VALUE' -%>

    <%= numo_type %>(Numo::NArray & na):
      <%= numo_type %>(na.shape()) {
      std::memcpy(NArray::write_ptr(), na.read_ptr(), na.size() * sizeof(<%= type %>));
    }

    size_t type_size() const override {
      return sizeof(<%= type %>);
    }
  <%- end -%>

    Numo::Type type_id() const override {
      return Numo::Type::<%= numo_type %>;
    }

    const char * type_name() const override {
      return "<%= numo_type %>";
    }

    const <%= type %> * read_ptr() {
      return reinterpret_cast< const <%= type %> * >(NArray::read_ptr());
    }

    <%= type %> * write_ptr() {
      return reinterpret_cast< <%= type %> * >(NArray::write_ptr());
    }

    private:

    VALUE dtype() const override {
      return numo_c<%= numo_type %>;
    }
  };
  <%- end -%>
  <%- compile_vars[:numeric_types].each_key do |numo_type| -%>

  inline NArray::operator <%= numo_type %> * () const {
    return dynamic_cast< <%= numo_type %> * >(const_cast< NArray * >(this));
  }

  inline NArray::operator <%= numo_type %> & () const {
    return dynamic_cast< <%= numo_type %> & >(*const_cast< NArray * >(this));
  }
  <%- end -%>

  using NType = std::variant< <%= compile_vars[:numeric_types].keys.join(', ') %> >;

  Numo::NType build(Numo::Type type_id, std::initializer_list< size_t > shape) {
    switch (type_id) {
    <%- compile_vars[:numeric_types].each_key do |numo_type| -%>
    case Type::<%= numo_type %>: return Numo::<%= numo_type %>(shape);
    <%- end -%>
    default:
      throw RuntimeError("invalid Numo::Type");
    }
  }

  Numo::NType build(Numo::Type type_id, std::vector< size_t > shape) {
    switch (type_id) {
    <%- compile_vars[:numeric_types].each_key do |numo_type| -%>
    case Type::<%= numo_type %>: return Numo::<%= numo_type %>(shape);
    <%- end -%>
    default:
      throw RuntimeError("invalid Numo::Type");
    }
  }

  Numo::NType cast(const Numo::NArray & v, Numo::Type type_id) {
    switch (type_id) {
    <%- compile_vars[:numeric_types].each_key do |numo_type| -%>
    case Type::<%= numo_type %>: return Numo::<%= numo_type %>(v);
    <%- end -%>
    default:
      throw RuntimeError("invalid Numo::Type");
    }
  }

  Numo::NArray & cast(Numo::NType & v) {
    switch (v.index()) {
    <%- compile_vars[:numeric_types].size.times do |i| -%>
    case <%= i %>: return std::get< <%= i %> >(v);
    <%- end -%>
    default:
      throw RuntimeError("invalid Numo::NType");
    }
  }
  <%- ['SComplex', 'DComplex', 'Bit'].each do |numo_type| -%>

  class <%= numo_type %> : public NArray {
    public:

    <%= numo_type %>(VALUE v) {
      construct_value(dtype(), v);
    }

    <%= numo_type %>(Rice::Object o) {
      construct_value(dtype(), o.value());
    }

    explicit <%= numo_type %>(std::initializer_list< size_t > shape) {
      construct_shape(dtype(), shape);
    }

    explicit <%= numo_type %>(std::vector< size_t > shape) {
      construct_shape(dtype(), shape);
    }

    Numo::Type type_id() const override {
      return Numo::Type::<%= numo_type %>;
    }

    const char * type_name() const override {
      return "<%= numo_type %>";
    }

    private:

    VALUE dtype() const override {
      return numo_c<%= numo_type %>;
    }
  };
  <%- end -%>
}

namespace Rice::detail {
  <%- compile_vars[:numo_types].each do |numo_type| -%>

  template<>
  struct Type< Numo::<%= numo_type %> > {
    static bool verify() { return true; }
  };

  template<>
  class From_Ruby< Numo::<%= numo_type %> > {
    public:

    Convertible is_convertible(VALUE value) {
      switch (rb_type(value)) {
      case RUBY_T_DATA:
        return Data_Type< Numo::<%= numo_type %> >::is_descendant(value) ? Convertible::Exact : Convertible::None;
      case RUBY_T_ARRAY:
        return Convertible::Cast;
      default:
        return Convertible::None;
      }
    }

    Numo::<%= numo_type %> convert(VALUE x) {
      return Numo::<%= numo_type %>(x);
    }
  };

  template<>
  class From_Ruby< Numo::<%= numo_type %> & > {
    public:

    Convertible is_convertible(VALUE value) {
      switch (rb_type(value)) {
      case RUBY_T_DATA:
        return Data_Type< Numo::<%= numo_type %> >::is_descendant(value) ? Convertible::Exact : Convertible::None;
      case RUBY_T_ARRAY:
        return Convertible::Cast;
      default:
        return Convertible::None;
      }
    }

    Numo::<%= numo_type %> & convert(VALUE x) {
      this->converted_ = Numo::<%= numo_type %>(x);
      return converted_;
    }

    private:

    Numo::<%= numo_type %> converted_;
  };

  template<>
  class To_Ruby< Numo::<%= numo_type %> > {
    public:

    VALUE convert(const Numo::<%= numo_type %>& x) {
      return x.value();
    }
  };

  template<>
  class To_Ruby< Numo::<%= numo_type %> & > {
    public:

    VALUE convert(const Numo::<%= numo_type %>& x) {
      return x.value();
    }
  };
  <%- end -%>
}
