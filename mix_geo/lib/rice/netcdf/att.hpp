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

    static auto write(int file_id, int var_id, const string & name, const string & type_or_text, const vector< double > & values = {}) {
      if (values.empty()) {
        check_status( nc_put_att_text(file_id, var_id, name.c_str(), type_or_text.size(), type_or_text.c_str()) );
        return Att(file_id, var_id, name);
      }
      switch (Base::type_id(type_or_text)) {
      <%- [
        ['NC_BYTE',  'signed char', 'schar'],
        ['NC_SHORT', 'short',       'short'],
        ['NC_INT',   'int',         'int'],
        ['NC_FLOAT', 'float',       'float'],
      ].each do |nc_type, type, suffix| -%>
      case <%= nc_type %>: {
        vector< <%= type %> > numbers(vector_cast< double, <%= type %> >(values));
        check_status( nc_put_att_<%= suffix %>(file_id, var_id, name.c_str(), <%= nc_type %>, numbers.size(), numbers.data()) );
        break;
      }
      <%- end -%>
      case NC_DOUBLE:
        check_status( nc_put_att_double(file_id, var_id, name.c_str(), NC_DOUBLE, values.size(), values.data()) );
        break;
      default:
        throw TypeError();
      }
      return Att(file_id, var_id, name);
    }

    void rename(const string & new_name) {
      check_status( nc_rename_att(file_id, var_id, name.c_str(), new_name.c_str()) );
      this->name = new_name;
    }

    auto type_name() const {
      return Base::type_name(type_id());
    }

    auto size() const {
      size_t size;
      check_status( nc_inq_attlen(file_id, var_id, name.c_str(), &size) );
      return size;
    }

    auto read() const {
      size_t count = size();
      switch (type_id()) {
      <%- [
        ['NC_BYTE',  'signed char', 'schar'],
        ['NC_SHORT', 'short',       'short'],
        ['NC_INT',   'int',         'int'],
        ['NC_FLOAT', 'float',       'float'],
      ].each do |nc_type, type, suffix| -%>
      case <%= nc_type %>: {
        <%= type %> numbers[count];
        check_status( nc_get_att_<%= suffix %>(file_id, var_id, name.c_str(), numbers) );
        return VectorType(vector_cast< <%= type %>, double >(numbers, count));
      }
      <%- end -%>
      case NC_DOUBLE: {
        double numbers[count];
        check_status( nc_get_att_double(file_id, var_id, name.c_str(), numbers) );
        return VectorType(vector< double >(numbers, numbers + count));
      }
      case NC_CHAR: {
        size_t count = size();
        char text[count + 1];
        text[count]= '\0';
        check_status( nc_get_att_text(file_id, var_id, name.c_str(), text) );
        return VectorType(string(text));
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
