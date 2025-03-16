namespace NetCDF {
  class Dim : public BelongsToFile {
    public:

    using BelongsToFile::BelongsToFile;

    static auto all(int file_id) {
      int count;
      check_status( nc_inq_ndims(file_id, &count) );
      int ids[count];
      check_status( nc_inq_dimids(file_id, NULL, ids, 0) );
      vector< Dim > dims(count);
      for (size_t i = 0; i < count; ++i) {
        dims[i].file_id = file_id;
        dims[i].id = ids[i];
      }
      return dims;
    }

    static auto create(int file_id, const string & name, size_t size = NC_UNLIMITED) {
      int dim_id;
      check_status( nc_def_dim(file_id, name.c_str(), size, &dim_id) );
      return Dim(file_id, dim_id);
    }

    auto name() const {
      char name[NC_MAX_NAME + 1];
      check_status( nc_inq_dimname(file_id, id, name) );
      return string(name);
    }

    // BUG: https://github.com/Unidata/netcdf-c/issues/597
    void rename(const string & new_name) const {
      check_status( nc_rename_dim(file_id, id, new_name.c_str()) );
    }

    auto size() const {
      size_t size;
      check_status( nc_inq_dimlen(file_id, id, &size) );
      return size;
    }

    bool is_unlimited() const {
      int count;
      check_status( nc_inq_unlimdims(file_id, &count, NULL) );
      if (count == 0) return false;
      int ids[count];
      check_status( nc_inq_unlimdims(file_id, NULL, ids) );
      for (size_t i = 0; i < count; ++i) if (ids[i] == id) return true;
      return false;
    }
  };
}
