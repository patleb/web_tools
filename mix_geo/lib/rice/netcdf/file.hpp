namespace NetCDF {
  class File : public Base {
    public:

    string path;
    string mode;
    bool nc4_classic;
    bool classic;
    bool share;

    using Base::Base;

    explicit File(const string & path, string mode = "r", bool nc4_classic = false, bool classic = false, bool share = false):
      Base() {
      open(path, mode);
    }

    File (const File &) = delete;
    File & operator=(const File &) = delete;

    ~File() {
      try {
        close();
      }
      catch (std::exception & e) {
        log_error(e.what());
      }
    }

    void open(const string & path, string mode = "r", bool nc4_classic = false, bool classic = false, bool share = false) {
      if (!is_null()) throw RuntimeError("file already opened");
      int flags;
      bool create = false;
      if (mode == "r") {
        flags = NC_NOWRITE;
      } else if (mode == "w") {
        flags = NC_CLOBBER;
        create = true;
      } else if (mode == "a") {
        if (std::filesystem::exists(path)) {
          flags = NC_WRITE;
        } else {
          flags = NC_NOCLOBBER;
          create = true;
        }
      } else {
        throw RuntimeError("mode not supported");
      }
      if (classic && share) flags = flags | NC_SHARE;
      if (create) {
        if (!classic) flags = flags | NC_NETCDF4;
        if (nc4_classic) flags = flags | NC_CLASSIC_MODEL;
        check_status( nc_create(path.c_str(), flags, &this->id) );
      } else {
        check_status( nc_open(path.c_str(), flags, &this->id) );
      }
      if (classic) BelongsToFile::classic_files.insert(id);
      this->path = path;
      this->mode = mode;
      this->nc4_classic = nc4_classic;
      this->classic = classic;
      this->share = share;
    }

    void close() {
      if (is_null()) return;
      check_status( nc_close(id) );
      BelongsToFile::classic_files.erase(id);
      this->id = NULL_ID;
    }

    void sync() const {
      check_status( nc_sync(id) );
    }

    void set_define_mode(bool define_mode) {
      if (define_mode) {
        check_status( nc_redef(id) );
      } else {
        check_status( nc_enddef(id) );
      }
    }

    auto set_fill(bool fill) {
      int mode, mode_was;
      mode = fill ? NC_FILL : NC_NOFILL;
      check_status( nc_set_fill(id, mode, &mode_was) );
      return mode != mode_was;
    }

    auto dims() const {
      return Dim::all(id);
    }

    auto vars() const {
      return Var::all(id);
    }

    auto atts() const {
      return Att::all(id, NC_GLOBAL);
    }

    auto create_dim(const string & name, size_t size = NC_UNLIMITED) const {
      return Dim::create(id, name, size);
    }

    auto create_var(const string & name, std::string_view type_name, const vector< Dim > & dims) const {
      return Var::create(id, name, type_name, dims);
    }

    auto write_att(const string & name, std::string_view type_name, numo::NArray values) const {
      return Att::write(id, NC_GLOBAL, name, NetCDF::type_id(type_name), values);
    }

    auto write_att_s(const string & name, const string & text) const {
      return Att::write_s(id, NC_GLOBAL, name, text);
    }
  };

  void Att::copy(const File & dst) const {
    check_status( nc_copy_att(file_id, var_id, name.c_str(), dst.id, NC_GLOBAL) );
  }
}
