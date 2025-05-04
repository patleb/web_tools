#undef STRCASECMP
#undef STRNCASECMP
#include <gdal_priv.h>
#include <gdalwarper.h>
#include "mix_geo/gdal/type.hpp"
#include "mix_geo/gdal/base.hpp"
#include "mix_geo/gdal/vector.hpp"
#include "mix_geo/gdal/raster.hpp"

namespace GDAL {
  auto version() {
    return std::to_string(GDAL_VERSION_MAJOR) + "." + std::to_string(GDAL_VERSION_MINOR);
  }
}
