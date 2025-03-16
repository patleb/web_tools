#define NULL_ID -1

namespace NetCDF {
  using std::string;
  using std::vector;
  using namespace C;

  using ScalarType = std::variant<
    double,
    string
  >;
  using VectorType = std::variant<
    vector< double >,
    string
  >;
  using NVectorType = std::variant<
    numo::Int8,
    numo::Int16,
    numo::Int32,
    numo::SFloat,
    numo::DFloat,
    vector< string >
  >;

  enum Type {
    Int8 = NC_BYTE,        // 1
    Int16 = NC_SHORT,      // 3
    Int32 = NC_INT,        // 4
    SFloat = NC_FLOAT,     // 5
    DFloat = NC_DOUBLE,    // 6
    // UInt8 = NC_UBYTE,   // 7
    // UInt16 = NC_USHORT, // 8
    // UInt32 = NC_UINT,   // 9
    // Int64 = NC_INT64,   // 10
    // UInt64 = NC_UINT64, // 11
    String = NC_CHAR       // 2
  };

  class TypeError : public RuntimeError {
    public:

    TypeError():
      RuntimeError("unsupported type") {
    }
  };

  class Base {
    public:

    int id = NULL_ID;

    Base(){}

    explicit Base(int id):
      id(id) {
    }

    bool is_null() const {
      return id == NULL_ID;
    }

    protected:

    static int type_id(std::string_view name) {
      if (name == "Int8")   return NC_BYTE;
      if (name == "Int16")  return NC_SHORT;
      if (name == "Int32")  return NC_INT;
      if (name == "SFloat") return NC_FLOAT;
      if (name == "DFloat") return NC_DOUBLE;
      // if (name == "UInt8")  return NC_UBYTE;
      // if (name == "UInt16") return NC_USHORT;
      // if (name == "UInt32") return NC_UINT;
      // if (name == "Int64")  return NC_INT64;
      // if (name == "UInt64") return NC_UINT64;
      if (name == "String") return NC_CHAR;
      throw TypeError();
    }

    static string type_name(int id) {
      switch (id) {
      case NC_BYTE:   return "Int8";
      case NC_SHORT:  return "Int16";
      case NC_INT:    return "Int32";
      case NC_FLOAT:  return "SFloat";
      case NC_DOUBLE: return "DFloat";
      // case NC_UBYTE:  return "UInt8";
      // case NC_USHORT: return "UInt16";
      // case NC_UINT:   return "UInt32";
      // case NC_INT64:  return "Int64";
      // case NC_UINT64: return "UInt64";
      case NC_CHAR:   return "String";
      }
      throw TypeError();
    }

    static void check_status(int code) {
      if (code == NC_NOERR) {
        return;
      }
      const char * msg = 0;
      if (NC_ISSYSERR(code)) {
        msg = std::strerror(code);
        msg = msg ? msg : "unknown system error";
      } else {
        msg = nc_strerror(code);
      }
      throw RuntimeError(msg);
    }
  };

  class BelongsToFile : public Base {
    public:

    int file_id = NULL_ID;

    using Base::Base;

    BelongsToFile(int file_id, int id):
      Base(id),
      file_id(file_id) {
    }
  };
}
