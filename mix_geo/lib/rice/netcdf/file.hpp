namespace NetCDF {
  class File : public Base {
    public:

    string path;
    string mode;

    using Base::Base;

    explicit File(const string & path, string mode = "r"):
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
        log_warning(e.what());
      }
    }

    void open(const string & path, string mode = "r") {
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
      if (create) {
        check_status( nc_create(path.c_str(), flags | NC_NETCDF4, &this->id) );
      } else {
        check_status( nc_open(path.c_str(), flags, &this->id) );
      }
      this->path = path;
      this->mode = mode;
      Dim::renamed = false;
    }

    void reopen(string mode = "r") {
      open(path, mode);
    }

    void close() {
      if (is_null()) return;
      nc_close(id);
      this->id = NULL_ID;
    }

    void reload() {
      close();
      reopen(mode);
    }

    void sync() const {
      check_status( nc_sync(id) );
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

    auto write_att(const string & name, const string & type_or_text, const vector< double > & values = {}) const {
      return Att::write(id, NC_GLOBAL, name, type_or_text, values);
    }
  };

  void Att::copy(const File & dst) const {
    check_status( nc_copy_att(file_id, var_id, name.c_str(), dst.id, NC_GLOBAL) );
  }
}
