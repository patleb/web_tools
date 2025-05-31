#undef STRCASECMP
#undef STRNCASECMP
#include <proj.h>
#include <gdal_priv.h>
#include "mix_geo/gdal/base.hpp"
#include "mix_geo/gdal/vector.hpp"
#include "mix_geo/gdal/raster.hpp"

namespace PROJ {
  auto version() {
    return std::to_string(PROJ_VERSION_MAJOR) + "." +
           std::to_string(PROJ_VERSION_MINOR) + "." +
           std::to_string(PROJ_VERSION_PATCH);
  }
}

namespace GDAL {
  auto version() {
    return std::to_string(GDAL_VERSION_MAJOR) + "." +
           std::to_string(GDAL_VERSION_MINOR) + "." +
           std::to_string(GDAL_VERSION_REV);
  }
}
