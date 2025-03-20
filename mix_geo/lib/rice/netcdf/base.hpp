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
  };

  class BelongsToFile : public Base {
    public:

    static std::set< int > classic_files;

    int file_id = NULL_ID;

    using Base::Base;

    BelongsToFile(int file_id, int id):
      Base(id),
      file_id(file_id) {
    }

    protected:

    // BUG: https://github.com/Unidata/netcdf-c/issues/597
    static void check_classic(int file_id, CONTEXT(trace, source)) {
      if (!classic_files.contains(file_id)) {
        throw RuntimeError("not a classic file", trace, source);
      }
    }
  };

  std::set< int > BelongsToFile::classic_files;
}
