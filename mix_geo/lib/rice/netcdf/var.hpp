namespace NetCDF {
  class Var : public BelongsToFile {
    public:

    using BelongsToFile::BelongsToFile;

    static auto all(int file_id) {
      int count;
      check_status( nc_inq_nvars(file_id, &count) );
      int ids[count];
      check_status( nc_inq_varids(file_id, NULL, ids) );
      vector< Var > vars(count);
      for (size_t i = 0; i < count; ++i) {
        vars[i].file_id = file_id;
        vars[i].id = ids[i];
      }
      return vars;
    }

    static auto create(int file_id, const string & name, std::string_view type_name, const vector< Dim > & dims) {
      int var_id;
      int count = dims.size();
      int ids[count];
      for (size_t i = 0; i < count; ++i) {
        ids[i] = dims[i].id;
      }
      check_status( nc_def_var(file_id, name.c_str(), NetCDF::type_id(type_name), count, ids, &var_id) );
      return Var(file_id, var_id);
    }

    auto name() const {
      char name[NC_MAX_NAME + 1];
      check_status( nc_inq_varname(file_id, id, name) );
      return string(name);
    }

    void rename(string new_name) const {
      check_classic(file_id);
      check_status( nc_rename_var(file_id, id, new_name.c_str()) );
    }

    auto type() const {
      return NetCDF::type(type_id());
    }

    auto dims_count() const {
      int count;
      check_status( nc_inq_varndims(file_id, id, &count) );
      return count;
    }

    auto dims() const {
      int count = dims_count();
      int ids[count];
      check_status( nc_inq_vardimid(file_id, id, ids) );
      vector< Dim > dims(count);
      for (size_t i = 0; i < count; ++i) {
        dims[i].file_id = file_id;
        dims[i].id = ids[i];
      }
      return dims;
    }

    auto atts() const {
      return Att::all(file_id, id);
    }

    auto shape() const {
      vector< Dim > dims = this->dims();
      int count = dims.size();
      vector< size_t > sizes(count);
      for (size_t i = 0; i < count; ++i) {
        sizes[i] = dims[i].size();
      }
      return sizes;
    }

    auto write_att(const string & name, std::string_view type_name, numo::NArray values) const {
      return Att::write(file_id, id, name, NetCDF::type_id(type_name), values);
    }

    auto write_att_s(const string & name, const string & text) const {
      return Att::write_s(file_id, id, name, text);
    }

    void write(numo::NArray values, const vector< size_t > & start = {}, const vector< ptrdiff_t > & stride = {}) const {
      if (type_id() == NC_CHAR) throw TypeError();
      size_t dims_count = this->dims_count();
      vector< size_t > starts = start.empty() ? vector< size_t >(dims_count, 0) : start;
      vector< size_t > counts = values.shape();
      if (starts.size() != dims_count) throw TypeError();
      if (counts.size() != dims_count) throw TypeError();
      const void * data = values.read_ptr();
      if (stride.empty()) {
        check_status( nc_put_vara(file_id, id, starts.data(), counts.data(), data) );
      } else {
        if (stride.size() != dims_count) throw TypeError();
        check_status( nc_put_vars(file_id, id, starts.data(), counts.data(), stride.data(), data) );
      }
    }

    void write_s(const vector< string > & values, size_t start = 0, ptrdiff_t stride = 1) const {
      size_t count = values.size();
      size_t starts[2] = { 0, 0 };
      size_t counts[2] = { 1, 0 };
      ptrdiff_t strides[2] = { stride, 1 };
      for (size_t i = 0; i < count; ++i) {
        starts[0] = start + i;
        counts[1] = values[i].size(); // without '\0'
        check_status( nc_put_vars_text(file_id, id, starts, counts, strides, values[i].c_str()) );
      }
    }

    auto read(const vector< size_t > & start = {}, const vector< size_t > & count = {}, const vector< ptrdiff_t > & stride = {}) const {
      switch (type_id()) {
      <%- compile_vars[:netcdf].each do |numo_type, nc_type| -%>
      case <%= nc_type %>: {
        size_t dims_count = this->dims_count();
        vector< size_t > starts = start.empty() ? vector< size_t >(dims_count, 0) : start;
        vector< size_t > counts = count.empty() ? vector< size_t >(dims_count, 1) : count;
        if (starts.size() != dims_count) throw TypeError();
        if (counts.size() != dims_count) throw TypeError();
        if (stride.empty()) {
          <%= numo_type %> values(counts);
          check_status( nc_get_vara(file_id, id, starts.data(), counts.data(), values.write_ptr()) );
          return NVectorType(values);
        } else {
          if (stride.size() != dims_count) throw TypeError();
          <%= numo_type %> values(counts);
          check_status( nc_get_vars(file_id, id, starts.data(), counts.data(), stride.data(), values.write_ptr()) );
          return NVectorType(values);
        }
      }
      <%- end -%>
      case NC_CHAR: {
        if (start.size() > 1) throw TypeError();
        if (count.size() > 1) throw TypeError();
        if (stride.size() > 1) throw TypeError();
        vector< size_t > sizes = shape();
        size_t max_count = sizes[0];
        size_t max_size = sizes[1];
        size_t start_0 = start.empty() ? 0 : start[0];
        size_t count_0 = count.empty() ? max_count : count[0];
        size_t starts[2] = { 0, 0 };
        size_t counts[2] = { 1, max_size };
        vector< string > values(count_0);
        if (stride.empty()) {
          for (size_t i = 0; i < count_0; ++i) {
            char data[max_size];
            starts[0] = start_0 + i;
            check_status( nc_get_vara_text(file_id, id, starts, counts, data) );
            values[i] = string(data);
          }
        } else {
          ptrdiff_t strides[2] = { stride[0], 1 };
          for (size_t i = 0; i < count_0; ++i) {
            char data[max_size];
            starts[0] = start_0 + i;
            check_status( nc_get_vars_text(file_id, id, starts, counts, strides, data) );
            values[i] = string(data);
          }
        }
        return NVectorType(values);
      }
      default:
        throw TypeError();
      }
    }

    auto fill_value() const {
      vector< Att > atts = this->atts();
      std::optional< NVectorType > value;
      int count = atts.size();
      if (count == 0) return value;
      for (size_t i = 0; i < count; ++i) {
        if (atts[i].name != "_FillValue") continue;
        value = atts[i].read();
        break;
      }
      return value;
    }

    void set_fill_value(numo::NArray value) const {
      Att::write(file_id, id, "_FillValue", type_id(), value, true);
    }

    bool fill() const {
      int no_fill;
      check_status( nc_inq_var_fill(file_id, id, &no_fill, NULL) );
      return no_fill != 1;
    }

    void set_fill(bool fill) const {
      int mode = fill ? NC_FILL : NC_NOFILL;
      check_status( nc_def_var_fill(file_id, id, mode, NULL) );
    }

    auto endian() const {
      int endian;
      check_status( nc_inq_var_endian(file_id, id, &endian) );
      return endian;
    }

    // endian: 0 to 2 (NC_ENDIAN_NATIVE, NC_ENDIAN_LITTLE, NC_ENDIAN_BIG)
    void set_endian(int endian) {
      check_status( nc_def_var_endian(file_id, id, endian) );
    }

    bool checksum() const {
      int checksum;
      check_status( nc_inq_var_fletcher32(file_id, id, &checksum) );
      return checksum == NC_FLETCHER32;
    }

    void set_checksum(bool checksum) const {
      check_status( nc_def_var_fletcher32(file_id, id, checksum) );
    }

    auto deflate() const {
      int settings[3];
      auto & [shuffle, deflate, level] = settings;
      check_status( nc_inq_var_deflate(file_id, id, &shuffle, &deflate, &level) );
      return vector< int >(settings, settings + 3);
    }

    // level: 0 to 9
    void set_deflate(bool shuffle, bool deflate, int level) const {
      if (!deflate) level = 0;
      if (level == 0) shuffle = deflate = false;
      check_status( nc_def_var_deflate(file_id, id, shuffle, deflate, level) );
    }

    auto quantize() const {
      int settings[2];
      auto & [quantize, nsd] = settings;
      check_status( nc_inq_var_quantize(file_id, id, &quantize, &nsd) );
      return vector< int >(settings, settings + 2);
    }

    // quantize: 0 to 3 (NC_NOQUANTIZE, NC_QUANTIZE_BITGROOM, NC_QUANTIZE_GRANULARBR, NC_QUANTIZE_BITROUND)
    // nsd: 1 to 7 (float) or 15 (double)
    void set_quantize(int quantize, int nsd) const {
      check_status( nc_def_var_quantize(file_id, id, quantize, nsd) );
    }

    auto chunking() const {
      int count = dims_count();
      int storage;
      size_t chunk_sizes[count];
      check_status( nc_inq_var_chunking(file_id, id, &storage, chunk_sizes) );
      vector< size_t > settings(count + 1);
      settings[0] = storage;
      for (size_t i = 0; i < count; ++i) settings[i + 1] = chunk_sizes[i];
      return settings;
    }

    // storage: 0 to 4 (NC_CHUNKED, NC_CONTIGUOUS, NC_COMPACT, NC_UNKNOWN_STORAGE, NC_VIRTUAL)
    void set_chunking(int storage, const vector< size_t > & chunk_sizes) const {
      check_status( nc_def_var_chunking(file_id, id, storage, chunk_sizes.data()) );
    }

    auto chunk_cache() const {
      size_t size, slots;
      float preemption;
      check_status( nc_get_var_chunk_cache(file_id, id, &size, &slots, &preemption) );
      return vector< std::variant< size_t, float > >({ size, slots, preemption });
    }

    // preemption: 0.0 to 1.0
    void set_chunk_cache(size_t size, size_t slots, float preemption) const {
      check_status( nc_set_var_chunk_cache(file_id, id, size, slots, preemption) );
    }

    private:

    int type_id() const {
      int type_id;
      check_status( nc_inq_vartype(file_id, id, &type_id) );
      return type_id;
    }
  };

  void Att::copy(const Var & dst) const {
    check_status( nc_copy_att(file_id, var_id, name.c_str(), dst.file_id, dst.id) );
  }
}
