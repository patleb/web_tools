namespace GDAL {
  using std::string;
  using std::vector;
  // using NaN  =  std::numeric_limits<double>::quiet_NaN(); // std::isnan(double)
  // using Inf  =  std::numeric_limits<double>::infinity();  // std::isinf(double) --> true also for NInf
  // using NInf = -std::numeric_limits<double>::infinity();  // double == NInf

  enum class AlgoType {
    Nearest  = GRA_NearestNeighbour, // 0
    Bilinear = GRA_Bilinear,         // 1
    Cubic    = GRA_Cubic,            // 2
    Spline   = GRA_CubicSpline,      // 3
    Lanczos  = GRA_Lanczos,          // 4
    Average  = GRA_Average,          // 5
    Mode     = GRA_Mode,             // 6
    Max      = GRA_Max,              // 8
    Min      = GRA_Min,              // 9
    Median   = GRA_Med,              // 10
    Q1       = GRA_Q1,               // 11
    Q3       = GRA_Q3,               // 12
    Sum      = GRA_Sum,              // 13
    RMS      = GRA_RMS,              // 14
  };

  enum class DataType {
    Unknown = GDT_Unknown, // 0
    Int8    = GDT_Int8,    // 14
    Int16   = GDT_Int16,   // 3
    Int32   = GDT_Int32,   // 5
    Int64   = GDT_Int64,   // 13
    SFloat  = GDT_Float32, // 6
    DFloat  = GDT_Float64, // 7
    UInt8   = GDT_Byte,    // 1
    UInt16  = GDT_UInt16,  // 2
    UInt32  = GDT_UInt32,  // 4
    UInt64  = GDT_UInt64,  // 12
  };

  auto gdal_type(Numo::Type type_id) {
    switch (type_id) {
    case Numo::Type::Int8:   return GDT_Int8;
    case Numo::Type::Int16:  return GDT_Int16;
    case Numo::Type::Int32:  return GDT_Int32;
    case Numo::Type::Int64:  return GDT_Int64;
    case Numo::Type::SFloat: return GDT_Float32;
    case Numo::Type::DFloat: return GDT_Float64;
    case Numo::Type::UInt8:  return GDT_Byte;
    case Numo::Type::UInt16: return GDT_UInt16;
    case Numo::Type::UInt32: return GDT_UInt32;
    case Numo::Type::UInt64: return GDT_UInt64;
    default:                 return GDT_Unknown;
    }
  }
}
