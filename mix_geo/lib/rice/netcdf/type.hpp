namespace NetCDF {
  using std::string;
  using std::vector;

  using NType = std::variant<
    vector< string >,
    Numo::Int8,
    Numo::Int16,
    Numo::Int32,
    Numo::Int64,
    Numo::SFloat,
    Numo::DFloat,
    Numo::UInt8,
    Numo::UInt16,
    Numo::UInt32,
    Numo::UInt64
  >;

  enum class Type {
    String = NC_CHAR,   // 2
    Int8   = NC_BYTE,   // 1
    Int16  = NC_SHORT,  // 3
    Int32  = NC_INT,    // 4
    Int64  = NC_INT64,  // 10
    SFloat = NC_FLOAT,  // 5
    DFloat = NC_DOUBLE, // 6
    UInt8  = NC_UBYTE,  // 7
    UInt16 = NC_USHORT, // 8
    UInt32 = NC_UINT,   // 9
    UInt64 = NC_UINT64, // 11
  };

  class TypeError : public RuntimeError {
    public:

    TypeError(CONTEXT(trace, source)):
      RuntimeError("TypeError", trace, source) {
    }
  };

  int type_id(const NetCDF::NType & values) {
    switch (values.index()) {
    case 0:  return NC_CHAR;
    case 1:  return NC_BYTE;
    case 2:  return NC_SHORT;
    case 3:  return NC_INT;
    case 4:  return NC_INT64;
    case 5:  return NC_FLOAT;
    case 6:  return NC_DOUBLE;
    case 7:  return NC_UBYTE;
    case 8:  return NC_USHORT;
    case 9:  return NC_UINT;
    case 10: return NC_UINT64;
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

  auto type(int id) {
    switch (id) {
    case NC_CHAR:   return Type::String;
    case NC_BYTE:   return Type::Int8;
    case NC_SHORT:  return Type::Int16;
    case NC_INT:    return Type::Int32;
    case NC_INT64:  return Type::Int64;
    case NC_FLOAT:  return Type::SFloat;
    case NC_DOUBLE: return Type::DFloat;
    case NC_UBYTE:  return Type::UInt8;
    case NC_USHORT: return Type::UInt16;
    case NC_UINT:   return Type::UInt32;
    case NC_UINT64: return Type::UInt64;
    }
    throw TypeError();
  }
}
