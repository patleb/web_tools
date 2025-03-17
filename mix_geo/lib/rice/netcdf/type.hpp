namespace NetCDF {
  using std::string;
  using std::vector;

  using NVectorType = std::variant<
    vector< string >,
    numo::Int8,
    numo::Int16,
    numo::Int32,
    numo::Int64,
    numo::SFloat,
    numo::DFloat,
    numo::UInt8,
    numo::UInt16,
    numo::UInt32,
    numo::UInt64
  >;

  enum Type {
    String,
    Int8,
    Int16,
    Int32,
    Int64,
    SFloat,
    DFloat,
    UInt8,
    UInt16,
    UInt32,
    UInt64,
  };

  class TypeError : public RuntimeError {
    public:

    TypeError():
      RuntimeError("unsupported type") {
    }
  };

  int type_id(const NVectorType & values) {
    switch (values.index()) {
    case 0:  return NC_CHAR;   // 2
    case 1:  return NC_BYTE;   // 1
    case 2:  return NC_SHORT;  // 3
    case 3:  return NC_INT;    // 4
    case 4:  return NC_INT64;  // 10
    case 5:  return NC_FLOAT;  // 5
    case 6:  return NC_DOUBLE; // 6
    case 7:  return NC_UBYTE;  // 7
    case 8:  return NC_USHORT; // 8
    case 9:  return NC_UINT;   // 9
    case 10: return NC_UINT64; // 11
    default: throw TypeError();
    }
  }

  int type_id(std::string_view name) {
    if (name == "String") return NC_CHAR;
    if (name == "Int8")   return NC_BYTE;
    if (name == "Int16")  return NC_SHORT;
    if (name == "Int32")  return NC_INT;
    if (name == "Int64")  return NC_INT64;
    if (name == "SFloat") return NC_FLOAT;
    if (name == "DFloat") return NC_DOUBLE;
    if (name == "UInt8")  return NC_UBYTE;
    if (name == "UInt16") return NC_USHORT;
    if (name == "UInt32") return NC_UINT;
    if (name == "UInt64") return NC_UINT64;
    throw TypeError();
  }

  string type_name(int id) {
    switch (id) {
    case NC_CHAR:   return "String";
    case NC_BYTE:   return "Int8";
    case NC_SHORT:  return "Int16";
    case NC_INT:    return "Int32";
    case NC_INT64:  return "Int64";
    case NC_FLOAT:  return "SFloat";
    case NC_DOUBLE: return "DFloat";
    case NC_UBYTE:  return "UInt8";
    case NC_USHORT: return "UInt16";
    case NC_UINT:   return "UInt32";
    case NC_UINT64: return "UInt64";
    }
    throw TypeError();
  }
}
