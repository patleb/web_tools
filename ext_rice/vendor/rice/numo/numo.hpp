/*!
 * Numo.hpp v0.2.0
 * https://github.com/ankane/numo.hpp
 * BSD-2-Clause License
 */

#pragma once

#include <rice/rice.hpp>
#include <numo/narray.h>

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

    size_t* shape() const {
      return RNARRAY_SHAPE(this->_value);
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
    ['Int64',   'long long'],
    ['UInt8',   'uint8_t'],
    ['UInt16',  'uint16_t'],
    ['UInt32',  'uint32_t'],
    ['UInt64',  'unsigned long long'],
    ['RObject', 'VALUE'],
  ].each do |na_type, type| -%>

  class <%= na_type %>: public NArray {
    public:

    <%= na_type %>(VALUE v) {
      construct_value(this->dtype(), v);
    }

    <%= na_type %>(Rice::Object o) {
      construct_value(this->dtype(), o.value());
    }

    <%= na_type %>(std::initializer_list<size_t> shape) {
      construct_shape(this->dtype(), shape);
    }

    <%= na_type %>(std::vector<size_t> shape) {
      construct_shape(this->dtype(), shape);
    }

    const <%= type %> * read_ptr() {
      return reinterpret_cast< const <%= type %> * >(NArray::read_ptr());
    }

    <%= type %> * write_ptr() {
      return reinterpret_cast< <%= type %> * >(NArray::write_ptr());
    }

    private:

    VALUE dtype() {
      return numo_c<%= na_type %>;
    }
  };
  <%- end -%>
  <%- ['SComplex', 'DComplex', 'Bit'].each do |na_type| -%>

  class <%= na_type %>: public NArray {
    public:

    <%= na_type %>(VALUE v) {
      construct_value(this->dtype(), v);
    }

    <%= na_type %>(Rice::Object o) {
      construct_value(this->dtype(), o.value());
    }

    <%= na_type %>(std::initializer_list<size_t> shape) {
      construct_shape(this->dtype(), shape);
    }

    <%= na_type %>(std::vector<size_t> shape) {
      construct_shape(this->dtype(), shape);
    }

    private:

    VALUE dtype() {
      return numo_c<%= na_type %>;
    }
  };
  <%- end -%>

}

namespace Rice::detail {
  <%- %w(NArray SFloat DFloat Int8 Int16 Int32 Int64 UInt8 UInt16 UInt32 UInt64 RObject SComplex DComplex Bit).each do |na_type| -%>

  template<>
  struct Type< numo::<%= na_type %> > {
    static bool verify() { return true; }
  };

  template<>
  class From_Ruby< numo::<%= na_type %> > {
    public:

    Convertible is_convertible(VALUE value) {
      switch (rb_type(value)) {
      case RUBY_T_DATA:
        return Data_Type< numo::<%= na_type %> >::is_descendant(value) ? Convertible::Exact : Convertible::None;
      case RUBY_T_ARRAY:
        return Convertible::Cast;
      default:
        return Convertible::None;
      }
    }

    numo::<%= na_type %> convert(VALUE x) {
      return numo::<%= na_type %>(x);
    }
  };

  template<>
  class To_Ruby<numo::<%= na_type %>> {
    public:

    VALUE convert(const numo::<%= na_type %>& x) {
      return x.value();
    }
  };
  <%- end -%>

}
