/*!
 * Numo.hpp v0.2.0
 * https://github.com/ankane/numo.hpp
 * BSD-2-Clause License
 */
<%- numo_types = %w(NArray SFloat DFloat Int8 Int16 Int32 Int64 UInt8 UInt16 UInt32 UInt64 RObject SComplex DComplex Bit) -%>

#pragma once

#include <rice/rice.hpp>
#include <numo/narray.h>

namespace Numo {
  enum Type {
  <%- numo_types.each_with_index do |numo_type| -%>
    <%= numo_type %>,
  <%- end -%>
  };
}

namespace numo {

  class NArray {
    public:

    NArray(VALUE v) {
      construct_value(this->dtype(), v);
    }

    NArray(Rice::Object o) {
      construct_value(this->dtype(), o.value());
    }

    VALUE value() const {
      return this->_value;
    }

    size_t ndim() const {
      return RNARRAY_NDIM(this->_value);
    }

    auto shape() const {
      size_t * shape = RNARRAY_SHAPE(this->_value);
      return std::vector< size_t >(shape, shape + ndim());
    }

    size_t size() const {
      return RNARRAY_SIZE(this->_value);
    }

    bool is_contiguous() const {
      return nary_check_contiguous(this->_value) == Qtrue;
    }

    operator Rice::Object() const {
      return Rice::Object(this->_value);
    }

    const void* read_ptr() {
      if (!is_contiguous()) {
        this->_value = nary_dup(this->_value);
      }
      return nary_get_pointer_for_read(this->_value) + nary_get_offset(this->_value);
    }

    void* write_ptr() {
      return nary_get_pointer_for_write(this->_value);
    }

    auto type_id() const {
      return Numo::Type::NArray;
    }

    auto type_name() const {
      return "NArray";
    }

    protected:

    NArray() { }

    void construct_value(VALUE dtype, VALUE v) {
      this->_value = rb_funcall(dtype, rb_intern("cast"), 1, v);
    }

    void construct_shape(VALUE dtype, std::initializer_list<size_t> shape) {
      // rb_narray_new doesn't modify shape, but not marked as const
      this->_value = rb_narray_new(dtype, shape.size(), const_cast<size_t*>(shape.begin()));
    }

    void construct_shape(VALUE dtype, std::vector<size_t> shape) {
      this->_value = rb_narray_new(dtype, shape.size(), shape.data());
    }

    VALUE _value;

    private:

    VALUE dtype() {
      return numo_cNArray;
    }
  };
  <%- [
    ['SFloat',  'float'],
    ['DFloat',  'double'],
    ['Int8',    'int8_t'],
    ['Int16',   'int16_t'],
    ['Int32',   'int32_t'],
    ['Int64',   'int64_t2'],
    ['UInt8',   'uint8_t'],
    ['UInt16',  'uint16_t'],
    ['UInt32',  'uint32_t'],
    ['UInt64',  'uint64_t2'],
    ['RObject', 'VALUE'],
  ].each do |numo_type, type| -%>

  class <%= numo_type %>: public NArray {
    public:

    <%= numo_type %>(VALUE v) {
      construct_value(this->dtype(), v);
    }

    <%= numo_type %>(Rice::Object o) {
      construct_value(this->dtype(), o.value());
    }

    <%= numo_type %>(std::initializer_list<size_t> shape) {
      construct_shape(this->dtype(), shape);
    }

    <%= numo_type %>(std::vector<size_t> shape) {
      construct_shape(this->dtype(), shape);
    }

    const <%= type %> * read_ptr() {
      return reinterpret_cast< const <%= type %> * >(NArray::read_ptr());
    }

    <%= type %> * write_ptr() {
      return reinterpret_cast< <%= type %> * >(NArray::write_ptr());
    }

    auto type_id() const {
      return Numo::Type::<%= numo_type %>;
    }

    auto type_name() const {
      return "<%= numo_type %>";
    }

    private:

    VALUE dtype() {
      return numo_c<%= numo_type %>;
    }
  };
  <%- end -%>
  <%- ['SComplex', 'DComplex', 'Bit'].each do |numo_type| -%>

  class <%= numo_type %>: public NArray {
    public:

    <%= numo_type %>(VALUE v) {
      construct_value(this->dtype(), v);
    }

    <%= numo_type %>(Rice::Object o) {
      construct_value(this->dtype(), o.value());
    }

    <%= numo_type %>(std::initializer_list<size_t> shape) {
      construct_shape(this->dtype(), shape);
    }

    <%= numo_type %>(std::vector<size_t> shape) {
      construct_shape(this->dtype(), shape);
    }

    auto type_id() const {
      return Numo::Type::<%= numo_type %>;
    }

    auto type_name() const {
      return "<%= numo_type %>";
    }

    private:

    VALUE dtype() {
      return numo_c<%= numo_type %>;
    }
  };
  <%- end -%>
}

namespace Rice::detail {
  <%- numo_types.each do |numo_type| -%>

  template<>
  struct Type< numo::<%= numo_type %> > {
    static bool verify() { return true; }
  };

  template<>
  class From_Ruby< numo::<%= numo_type %> > {
    public:

    Convertible is_convertible(VALUE value) {
      switch (rb_type(value)) {
      case RUBY_T_DATA:
        return Data_Type< numo::<%= numo_type %> >::is_descendant(value) ? Convertible::Exact : Convertible::None;
      case RUBY_T_ARRAY:
        return Convertible::Cast;
      default:
        return Convertible::None;
      }
    }

    numo::<%= numo_type %> convert(VALUE x) {
      return numo::<%= numo_type %>(x);
    }
  };

  template<>
  class From_Ruby< numo::<%= numo_type %> & > {
    public:

    Convertible is_convertible(VALUE value) {
      switch (rb_type(value)) {
      case RUBY_T_DATA:
        return Data_Type< numo::<%= numo_type %> >::is_descendant(value) ? Convertible::Exact : Convertible::None;
      case RUBY_T_ARRAY:
        return Convertible::Cast;
      default:
        return Convertible::None;
      }
    }

    numo::<%= numo_type %> & convert(VALUE x) {
      this->converted_ = numo::<%= numo_type %>(x);
      return converted_;
    }

    private:

    numo::<%= numo_type %> converted_;
  };

  template<>
  class To_Ruby< numo::<%= numo_type %> > {
    public:

    VALUE convert(const numo::<%= numo_type %>& x) {
      return x.value();
    }
  };

  template<>
  class To_Ruby< numo::<%= numo_type %> & > {
    public:

    VALUE convert(const numo::<%= numo_type %>& x) {
      return x.value();
    }
  };
  <%- end -%>
}
