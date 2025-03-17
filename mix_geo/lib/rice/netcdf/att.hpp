namespace NetCDF {
  class File;
  class Var;

  class Att : public BelongsToFile {
    public:

    int var_id = NULL_ID;
    string name;

    using BelongsToFile::BelongsToFile;

    Att(int file_id, int var_id, std::string_view name):
      BelongsToFile(file_id, NULL_ID),
      var_id(var_id),
      name(name) {
    }

    static auto all(int file_id, int var_id) {
      int count = 0;
      if (var_id == NC_GLOBAL) {
        check_status( nc_inq_natts(file_id, &count) );
      } else {
        check_status( nc_inq_varnatts(file_id, var_id, &count) );
      }
      vector< Att > atts(count);
      for (size_t i = 0; i < count; ++i) {
        char name[NC_MAX_NAME + 1];
        check_status( nc_inq_attname(file_id, var_id, i, name) );
        atts[i].file_id = file_id;
        atts[i].var_id = var_id;
        atts[i].name = string(name);
      }
      return atts;
    }
    <%- compile_vars[:netcdf][:types].each do |numo_type, (nc_type, type, suffix)| -%>

    static auto write(int file_id, int var_id, const string & name, <%= numo_type %> & values, size_t max_size = 0) {
      if (values.ndim() != 1) throw TypeError();
      if (max_size && values.size() > max_size) throw TypeError();
      const <%= type %> * data = values.read_ptr();
      check_status( nc_put_att_<%= suffix %>(file_id, var_id, name.c_str(), <%= nc_type %>, values.size(), data) );
      return Att(file_id, var_id, name);
    }
    <%- end -%>

    static auto write(int file_id, int var_id, const string & name, const vector< string > & values, size_t max_size = 0) {
      auto & text = values.front();
      if (values.size() != 1) throw TypeError();
      if (max_size && text.size() > max_size) throw TypeError();
      check_status( nc_put_att_text(file_id, var_id, name.c_str(), text.size(), text.c_str()) );
      return Att(file_id, var_id, name);
    }

    void rename(const string & new_name) {
      check_status( nc_rename_att(file_id, var_id, name.c_str(), new_name.c_str()) );
      this->name = new_name;
    }

    auto type_name() const {
      return NetCDF::type_name(type_id());
    }

    auto size() const {
      size_t size;
      check_status( nc_inq_attlen(file_id, var_id, name.c_str(), &size) );
      return size;
    }

    auto read() const {
      size_t count = size();
      switch (type_id()) {
      <%- compile_vars[:netcdf][:types].each do |numo_type, (nc_type, type, suffix)| -%>
      case <%= nc_type %>: {
        <%= numo_type %> numbers({ count });
        check_status( nc_get_att_<%= suffix %>(file_id, var_id, name.c_str(), numbers.write_ptr()) );
        return NVectorType(numbers);
      }
      <%- end -%>
      case NC_CHAR: {
        size_t count = size();
        char text[count + 1];
        text[count]= '\0';
        check_status( nc_get_att_text(file_id, var_id, name.c_str(), text) );
        return NVectorType(vector< string >{ string(text) });
      }
      default:
        throw TypeError();
      }
    }

    void destroy() const {
      check_status( nc_del_att(file_id, var_id, name.c_str()) );
    }

    void copy(const File & dst) const;

    void copy(const Var & dst) const;

    private:

    int type_id() const {
      int type_id;
      check_status( nc_inq_atttype(file_id, var_id, name.c_str(), &type_id) );
      return type_id;
    }
  };
}
