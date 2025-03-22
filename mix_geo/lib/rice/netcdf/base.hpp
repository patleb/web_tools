#define NULL_ID -1

namespace NetCDF {
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

    static auto file_format(int file_id) {
      int format;
      check_status( nc_inq_format(file_id, &format) );
      switch (format) {
      case NC_FORMAT_CLASSIC:         return "classic";     // 1
      case NC_FORMAT_64BIT_OFFSET:    return "classic_64";  // 2
      case NC_FORMAT_CDF5:            return "cdf5";        // 5
      case NC_FORMAT_NETCDF4:         return "nc4";         // 3
      case NC_FORMAT_NETCDF4_CLASSIC: return "nc4_classic"; // 4
      default: throw RuntimeError("unknown file format");
      }
    }

    static void check_status(int code, CONTEXT(trace, source)) {
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
      throw RuntimeError(msg, trace, source);
    }

    // BUG: https://github.com/Unidata/netcdf-c/issues/597
    static void check_classic(int file_id, CONTEXT(trace, source)) {
      if (file_format(file_id) != "classic") {
        throw RuntimeError("not a classic file", trace, source);
      }
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
