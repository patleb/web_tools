#include "mix_geo/netcdf/type.hpp"
#include "mix_geo/netcdf/base.hpp"
#include "mix_geo/netcdf/dim.hpp"
#include "mix_geo/netcdf/att.hpp"
#include "mix_geo/netcdf/var.hpp"
#include "mix_geo/netcdf/file.hpp"

namespace NetCDF {
  inline auto version() {
    return string(nc_inq_libvers());
  }
}
