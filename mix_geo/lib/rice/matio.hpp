#include "mix_geo/matio/type.hpp"
#include "mix_geo/matio/base.hpp"
#include "mix_geo/matio/var.hpp"
#include "mix_geo/matio/file.hpp"

namespace MatIO {
  inline auto version() {
    return string(MATIO_VERSION_STR);
  }
}
