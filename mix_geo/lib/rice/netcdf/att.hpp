<%- types = [
  ['NC_BYTE',   'numo::Int8',   'int8_t',    'schar'],
  ['NC_SHORT',  'numo::Int16',  'int16_t',   'short'],
  ['NC_INT',    'numo::Int32',  'int32_t',   'int'],
  ['NC_INT64',  'numo::Int64',  'int64_t2',  'longlong'],
  ['NC_FLOAT',  'numo::SFloat', 'float',     'float'],
  ['NC_DOUBLE', 'numo::DFloat', 'double',    'double'],
  ['NC_UBYTE',  'numo::UInt8',  'uint8_t',   'uchar'],
  ['NC_USHORT', 'numo::UInt16', 'uint16_t',  'ushort'],
  ['NC_UINT',   'numo::UInt32', 'uint32_t',  'uint'],
  ['NC_UINT64', 'numo::UInt64', 'uint64_t2', 'ulonglong'],
] -%>
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

    static auto write(int file_id, int var_id, const string & name, NVectorType values, size_t max_size = 0) {
      switch (NetCDF::type_id(values)) {
      <%- types.each do |nc_type, na_type, type, suffix| -%>
      case <%= nc_type %>: {
        auto & numbers = std::get< <%= na_type %> >(values);
        if (numbers.ndim() != 1) throw TypeError();
        if (max_size && numbers.size() > max_size) throw TypeError();
        const <%= type %> * data = numbers.read_ptr();
        check_status( nc_put_att_<%= suffix %>(file_id, var_id, name.c_str(), <%= nc_type %>, numbers.size(), data) );
        break;
      }
      <%- end -%>
      case NC_CHAR: {
        auto & texts = std::get< vector< string > >(values);
        auto & text = texts.front();
        if (texts.size() != 1) throw TypeError();
        if (max_size && text.size() > max_size) throw TypeError();
        check_status( nc_put_att_text(file_id, var_id, name.c_str(), text.size(), text.c_str()) );
        break;
      }
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
      <%- types.each do |nc_type, na_type, type, suffix| -%>
      case <%= nc_type %>: {
        <%= na_type %> numbers({ count });
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
