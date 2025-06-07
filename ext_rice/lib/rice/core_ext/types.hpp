#define DOUBLE_SAFE_INT64 9007199254740991
#define S(value) + std::to_string((value)) +

typedef long long int64_t2;
typedef unsigned long long uint64_t2;

using Vbool = std::vector< bool >;
using Obool = std::optional< bool >;
using Vint = std::vector< int >;
using Oint = std::optional< int >;
using Vsize_t = std::vector< size_t >;
using Osize_t = std::optional< size_t >;
using Vssize_t = std::vector< ssize_t >;
using Ossize_t = std::optional< ssize_t >;
using Vptrdiff_t = std::vector< ptrdiff_t >;
using Optrdiff_t = std::optional< ptrdiff_t >;
<%- compile_vars[:numeric_types].each_value do |type| -%>
using V<%= type %> = std::vector< <%= type %> >;
using O<%= type %> = std::optional< <%= type %> >;
<%- end -%>
using Vstring = std::vector< std::string >;
using Ostring = std::optional< std::string >;

constexpr auto nil = std::nullopt;

namespace Float {
  constexpr auto nan = std::numeric_limits< double >::quiet_NaN(); // std::isnan(double)
  constexpr auto inf = std::numeric_limits< double >::infinity();  // std::isinf(double) --> true also for -inf
}
