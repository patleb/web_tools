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
      check_status( nc_def_var(file_id, name.c_str(), Base::type_id(type_name), count, ids, &var_id) );
      return Var(file_id, var_id);
    }

    auto name() const {
      char name[NC_MAX_NAME + 1];
      check_status( nc_inq_varname(file_id, id, name) );
      return string(name);
    }

    void rename(string new_name) const {
      check_status( nc_rename_var(file_id, id, new_name.c_str()) );
    }

    auto type_name() const {
      return Base::type_name(type_id());
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

    auto write_att(const string & name, const string & type_or_text, const vector< double > & values = {}) const {
      return Att::write(file_id, id, name, type_or_text, values);
    }

    void write(NVectorType values, const vector< size_t > & starts = {}, const vector< size_t > & counts = {}, const vector< ptrdiff_t > & strides = {}) const {
      switch (type_id()) {
      <%- [
        ['NC_BYTE',   'numo::Int8',   'signed char',        'schar'],
        ['NC_SHORT',  'numo::Int16',  'short',              'short'],
        ['NC_INT',    'numo::Int32',  'int',                'int'],
        ['NC_INT64',  'numo::Int64',  'long long',          'longlong'],
        ['NC_FLOAT',  'numo::SFloat', 'float',              'float'],
        ['NC_DOUBLE', 'numo::DFloat', 'double',             'double'],
        ['NC_UBYTE',  'numo::UInt8',  'unsigned char',      'uchar'],
        ['NC_USHORT', 'numo::UInt16', 'unsigned short',     'ushort'],
        ['NC_UINT',   'numo::UInt32', 'unsigned int',       'uint'],
        ['NC_UINT64', 'numo::UInt64', 'unsigned long long', 'ulonglong'],
      ].each do |nc_type, na_type, type, suffix| -%>
      case <%= nc_type %>: {
        const <%= type %> * data = std::get< <%= na_type %> >(values).read_ptr();
        if (starts.empty()) {
          check_status( nc_put_var_<%= suffix %>(file_id, id, data) );
        } else if (strides.empty()) {
          check_status( nc_put_vara_<%= suffix %>(file_id, id, starts.data(), counts.data(), data) );
        } else {
          check_status( nc_put_vars_<%= suffix %>(file_id, id, starts.data(), counts.data(), strides.data(), data) );
        }
        break;
      }
      <%- end -%>
      case NC_CHAR: {
        vector< char * > strings = vector_cast< string, char >(std::get< vector< string >>(values));
        const char * data = reinterpret_cast< const char * >(strings.data());
        try {
          check_status( nc_put_var_text(file_id, id, data) );
          vector_free(strings);
        }
        catch (...) {
          vector_free(strings);
          throw;
        }
      }
      default:
        throw TypeError();
      }
    }

    auto read(const vector< size_t > & starts = {}, const vector< size_t > & counts = {}, const vector< ptrdiff_t > & strides = {}) const {
      switch (type_id()) {
      <%- [
        ['NC_BYTE',   'numo::Int8',   'signed char',        'schar'],
        ['NC_SHORT',  'numo::Int16',  'short',              'short'],
        ['NC_INT',    'numo::Int32',  'int',                'int'],
        ['NC_INT64',  'numo::Int64',  'long long',          'longlong'],
        ['NC_FLOAT',  'numo::SFloat', 'float',              'float'],
        ['NC_DOUBLE', 'numo::DFloat', 'double',             'double'],
        ['NC_UBYTE',  'numo::UInt8',  'unsigned char',      'uchar'],
        ['NC_USHORT', 'numo::UInt16', 'unsigned short',     'ushort'],
        ['NC_UINT',   'numo::UInt32', 'unsigned int',       'uint'],
        ['NC_UINT64', 'numo::UInt64', 'unsigned long long', 'ulonglong'],
      ].each do |nc_type, na_type, type, suffix| -%>
      case <%= nc_type %>: {
        if (starts.empty()) {
          <%= na_type %> values(shape());
          check_status( nc_get_var_<%= suffix %>(file_id, id, values.write_ptr()) );
          return NVectorType(values);
        } else if (strides.empty()) {
          <%= na_type %> values(counts);
          check_status( nc_get_vara_<%= suffix %>(file_id, id, starts.data(), counts.data(), values.write_ptr()) );
          return NVectorType(values);
        } else {
          <%= na_type %> values(counts);
          check_status( nc_get_vars_<%= suffix %>(file_id, id, starts.data(), counts.data(), strides.data(), values.write_ptr()) );
          return NVectorType(values);
        }
      }
      <%- end -%>
      case NC_CHAR: {
        vector< size_t > sizes = shape();
        size_t count = sizes[0];
        size_t max_size = sizes[1];
        vector< char * > strings;
        for (size_t i = 0; i < count; ++i) strings[i] = new char[max_size];
        char * data = reinterpret_cast< char * >(strings.data());
        try {
          check_status( nc_get_var_text(file_id, id, data) );
          vector< string > values = vector_cast< char, string >(data, count);
          vector_free(strings);
          return NVectorType(values);
        }
        catch (...) {
          vector_free(strings);
          throw;
        }
      }
      default:
        throw TypeError();
      }
    }

    auto fill_value() const {
      vector< Att > atts = this->atts();
      std::optional< ScalarType > value;
      int count = atts.size();
      if (count == 0) return value;
      for (size_t i = 0; i < count; ++i) {
        if (atts[i].name != "_FillValue") continue;
        VectorType values = atts[i].read();
        if (type_id() == NC_CHAR) {
          value = std::get< string >(values);
        } else {
          value = std::get< vector< double >>(values).front();
        }
        break;
      }
      return value;
    }

    void set_fill_value(ScalarType value) const {
      if (type_id() == NC_CHAR) {
        if (std::get< string >(value).size() != 1) throw TypeError();
        write_att("_FillValue", std::get< string >(value));
      } else {
        write_att("_FillValue", type_name(), { std::get< double >(value) });
      }
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
