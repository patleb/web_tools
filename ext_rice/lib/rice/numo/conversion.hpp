namespace numo {
  template < class N >
  VALUE to_sql(VALUE self) {
    size_t ndim = RNARRAY_NDIM(self);
    if (ndim == 0) {
      RB_GC_GUARD(self);
      return rb_str_new_cstr("{}");
    }
    size_t size = RNARRAY_SIZE(self);
    if (size == 0) {
      char sql[2 * ndim + 1];
      size_t i = 0;
      for (; i < ndim; ++i) sql[i] = '{';
      for (; i < 2 * ndim; ++i) sql[i] = '}';
      sql[i] = '\0';
      RB_GC_GUARD(self);
      return rb_str_new_cstr(sql);
    }
    narray_t * na;
    GetNArray(self, na);
    size_t offset = 0;
    if (na->type == NARRAY_VIEW_T) {
      if (na_check_contiguous(self) == Qtrue) {
        offset = NA_VIEW_OFFSET(na);
      } else {
        self = rb_funcall(self, rb_intern("dup"), 0);
      }
    }
    char * data = na_get_pointer_for_read(self) + offset;
    size_t stride = nary_element_stride(self);
    size_t dim_i = 0, dim_j;
    size_t dim_n = ndim - 1;
    size_t counts[ndim];
    size_t * shape = RNARRAY_SHAPE(self);
    std::memcpy(counts, shape, ndim * sizeof(size_t));
    std::stringstream sql;
    while (true) {
      while (true) {
        sql << '{';
        if (dim_i == dim_n) break;
        ++dim_i;
      }
      while (true) {
        sql << std::format("{}", *reinterpret_cast< N * >(data));
        data += stride;
        if (--counts[dim_i] == 0) break;
        sql << ',';
      }
      while (true) {
        sql << '}';
        if (dim_i == 0) {
          RB_GC_GUARD(self);
          return rb_str_new_cstr(sql.str().c_str());
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

  void init_conversion() {
    <%- [
      ['SFloat', 'float'],
      ['DFloat', 'double'],
      ['Int8',   'int8_t'],
      ['Int16',  'int16_t'],
      ['Int32',  'int32_t'],
      ['Int64',  'int64_t2'],
      ['UInt8',  'uint8_t'],
      ['UInt16', 'uint16_t'],
      ['UInt32', 'uint32_t'],
      ['UInt64', 'uint64_t2'],
    ].each do |numo_type, type| -%>
    rb_define_method(numo_c<%= numo_type %>, "to_sql", numo::to_sql< <%= type %> >, 0);
    <%- end -%>
  }
}
