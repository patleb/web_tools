namespace NetCDF {
  class Dim : public BelongsToFile {
    public:

    using BelongsToFile::BelongsToFile;

    static vector< Dim > all(int file_id) {
      int count;
      Base::check_status( nc_inq_ndims(file_id, &count), file_id );
      int ids[count];
      Base::check_status( nc_inq_dimids(file_id, NULL, ids, 0), file_id );
      vector< Dim > dims(count);
      for (size_t i = 0; i < count; ++i) {
        dims[i].file_id = file_id;
        dims[i].id = ids[i];
      }
      return dims;
    }

    static Dim find(int file_id, const string & name) {
      int id;
      Base::check_status( nc_inq_dimid(file_id, name.c_str(), &id), file_id, NULL_ID, name );
      return Dim(file_id, id);
    }

    static Dim create(int file_id, const string & name, const Osize_t & size = nil) {
      int dim_id;
      Base::check_status( nc_def_dim(file_id, name.c_str(), size.value_or(NC_UNLIMITED), &dim_id), file_id );
      return Dim(file_id, dim_id);
    }

    string name() const {
      char name[NC_MAX_NAME + 1];
      check_status( nc_inq_dimname(file_id, id, name) );
      return name;
    }

    void rename(const string & new_name) const {
      check_classic(file_id);
      check_status( nc_rename_dim(file_id, id, new_name.c_str()) );
    }

    size_t size() const {
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
