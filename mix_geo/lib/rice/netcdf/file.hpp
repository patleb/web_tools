namespace NetCDF {
  class File : public Base {
    public:

    string path;
    string mode;
    int flags;

    using Base::Base;

    explicit File(const string & path, Ostring mode = nil, Obool nc4_classic = nil, Obool classic = nil, Obool share = nil):
      Base() {
      open(path, mode, nc4_classic, classic, share);
    }
    <%= no_copy :File %>

    ~File() {
      try {
        close();
      }
      catch (std::exception & e) {
        log_error(e.what());
      }
    }

    void open(const string & path, Ostring mode = nil, Obool nc4_classic = nil, Obool classic = nil, Obool share = nil) {
      if (!is_closed()) throw RuntimeError("file already opened");
      auto _mode_ = mode.value_or("r");
      auto _nc4_classic_ = nc4_classic.value_or(false);
      auto _classic_ = classic.value_or(false);
      auto _share_ = share.value_or(false);
      int flags;
      bool create = false;
      if (_mode_ == "r") {
        flags = NC_NOWRITE;
      } else if (_mode_ == "w") {
        flags = NC_CLOBBER;
        create = true;
      } else if (_mode_ == "a") {
        if (std::filesystem::exists(path)) {
          flags = NC_WRITE;
        } else {
          flags = NC_NOCLOBBER;
          create = true;
        }
      } else {
        throw RuntimeError("mode not supported");
      }
      if (_classic_ && _share_) flags = flags | NC_SHARE;
      if (create) {
        if (!_classic_) flags = flags | NC_NETCDF4;
        if (_nc4_classic_) flags = flags | NC_CLASSIC_MODEL;
        check_status( nc_create(path.c_str(), flags, &this->id) );
      } else {
        check_status( nc_open(path.c_str(), flags, &this->id) );
      }
      this->path = path;
      this->mode = _mode_;
      this->flags = flags;
    }

    void close() {
      if (is_closed()) return;
      check_status( nc_close(id) );
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

    auto format() const {
      return Base::file_format(id);
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

    auto dim(const string & name) const {
      return Dim::find(id, name);
    }

    auto var(const string & name) const {
      return Var::find(id, name);
    }

    auto att(const string & name) const {
      return Att::find(id, NC_GLOBAL, name);
    }

    auto create_dim(const string & name, const Osize_t & size = nil) const {
      return Dim::create(id, name, size);
    }

    auto create_var(const string & name, std::string_view type_name, const vector< Dim > & dims) const {
      return Var::create(id, name, type_name, dims);
    }

    auto write_att(const string & name, std::string_view type_name, const Tensor::Base & values) const {
      return Att::write(id, NC_GLOBAL, name, NetCDF::type_id(type_name), values);
    }

    auto write_att_s(const string & name, const string & text) const {
      return Att::write_s(id, NC_GLOBAL, name, text);
    }

    protected:

    void check_status(int code, CONTEXT(trace, source)) const {
      Base::check_status(code, id, NULL_ID, "", trace, source);
    }

    private:

    bool is_closed() const {
      return id == NULL_ID;
    }
  };

  void Att::copy(const File & dst) const {
    check_status( nc_copy_att(file_id, var_id, name.c_str(), dst.id, NC_GLOBAL) );
  }
}
