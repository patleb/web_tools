namespace MatIO {
  class File : public Base {
    public:

    string path;
    string mode;
    std::map< string, Var > vars;

    using Base::Base;

    explicit File(const string & path, Ostring mode = nil, Oint version = nil):
      Base() {
      auto _mode_ = mode.value_or("r");
      auto _version_ = version.value_or(static_cast< int >(MAT_FT_DEFAULT));
      mat_acc access;
      bool create = false;
      if (_mode_ == "r") {
        access = MAT_ACC_RDONLY;
      } else if (_mode_ == "w") {
        create = true;
      } else if (_mode_ == "a") {
        if (std::filesystem::exists(path)) {
          access = MAT_ACC_RDWR;
        } else {
          create = true;
        }
      } else {
        throw RuntimeError("mode not supported");
      }
      if (create) {
        this->file = Mat_CreateVer(path.c_str(), NULL, static_cast< mat_ft >(_version_));
      } else {
        this->file = Mat_Open(path.c_str(), access);
      }
      if (file == NULL) throw RuntimeError("unable to open file");
      this->path = path;
      this->mode = _mode_;
      load_metadata();
    }
    <%= no_copy :File, indent: 4 %>

    ~File() {
      try {
        close();
      }
      catch (std::exception & e) {
        log_error(e.what());
      }
    }

    void close() {
      if (is_closed()) return;
      for (const auto & var : matvars) Mat_VarFree(var);
      Mat_Close(file);
      this->file = NULL;
    }

    bool is_closed() const {
      return file == NULL;
    }

    auto _vars_()  const { return vars; }
    auto header()  const { return string(Mat_GetHeader(file)); }
    auto version() const { return static_cast< int >(Mat_GetVersion(file)); }

    private:

    void load_metadata() {
      size_t count;
      char ** names = Mat_GetDir(file, &count);
      for (size_t i = 0; i < count; ++i) {
        auto var = Mat_VarReadInfo(file, names[i]);
        assign_info(string(names[i]), var);
        matvars.emplace_back(var);
      }
    }

    void assign_info(const string & name, matvar_t * var, const Ostring & scope = nil) {
      switch (var->class_type) {
      case MAT_C_STRUCT: {
        string structs_scope = nested_name(scope, name);
        size_t structs_count = nested_count(var);
        size_t fields_count = Mat_VarGetNumberOfFields(var);
        for (size_t struct_i = 0; struct_i < structs_count; ++struct_i) {
          string struct_scope = structs_scope + "." + std::to_string(struct_i);
          for (size_t field_i = 0; field_i < fields_count; ++field_i) {
            matvar_t * field_var = Mat_VarGetStructFieldByIndex(var, field_i, struct_i);
            assign_info(string(field_var->name), field_var, struct_scope);
          }
        }
        break;
      }
      case MAT_C_CELL: {
        string cell_scope = nested_name(scope, name);
        size_t cells_count = nested_count(var);
        for (size_t cell_i = 0; cell_i < cells_count; ++cell_i) {
          matvar_t * cell_var = Mat_VarGetCell(var, cell_i);
          assign_info(std::to_string(cell_i), cell_var, cell_scope);
        }
        break;
      }
      default:
        string path = scope ? scope.value() + "." + name : name;
        vars.try_emplace(path, file, name, path, var);
      }
    }

    string nested_name(const Ostring & scope, const string & name) const {
      if (scope) {
        return scope.value() + "." + name;
      } else {
        return name;
      }
    }

    size_t nested_count(matvar_t * var) const {
      size_t dims_count = var->rank;
      size_t count = 1;
      for (size_t i = 0; i < dims_count; ++i) count *= var->dims[i];
      return count;
    }

    vector< matvar_t * > matvars;
  };
}
