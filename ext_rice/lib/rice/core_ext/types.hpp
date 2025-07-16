#define DOUBLE_SAFE_INT64 9007199254740991
#define FLOAT_SAFE_INT32          16777215
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
<%- template[:numeric].each_value do |T| -%>
using V-T- = std::vector< T >;
using O-T- = std::optional< T >;
using VV-T- = std::vector< V-T- >;
<%- end -%>
using Vstring = std::vector< std::string >;
using Ostring = std::optional< std::string >;

constexpr auto nil = std::nullopt;

namespace Float {
  constexpr auto nan = std::numeric_limits< double >::quiet_NaN(); // std::isnan(double)
  constexpr auto inf = std::numeric_limits< double >::infinity();  // std::isinf(double) --> true also for -inf
}

template < class T >
auto vector_concat(std::initializer_list< std::vector< T >> vectors) {
  size_t count = 0;
  for (auto && v : vectors) count += v.size();
  std::vector< T > result(count); // gcc 15 --> result.append_range(v)
  for (auto && v : vectors) result.insert(result.end(), v.cbegin(), v.cend());
  return result;
}

template < class T >
auto & vector_concat(std::vector< T > & values, std::initializer_list< std::vector< T >> vectors) {
  size_t count = 0;
  for (auto && v : vectors) count += v.size();
  values.reserve(values.size() + count);
  for (auto && v : vectors) values.insert(values.end(), v.cbegin(), v.cend());
  return values;
}

template < class V, class T >
auto vector_cast(const std::vector< V > & values) {
  size_t count = values.size();
  std::vector< T > casts(count);
  for (size_t i = 0; i < count; ++i) {
    casts[i] = static_cast< T >(values[i]);
  }
  return casts;
}

template < class V, class T >
auto vector_cast(const V * values, size_t count) {
  std::vector< T > casts(count);
  for (size_t i = 0; i < count; ++i) {
    casts[i] = static_cast< T >(values[i]);
  }
  return casts;
}

template < class V, V >
auto vector_cast(const std::vector< V > & values) {
  return std::vector< V >(values);
}

template < class V, V >
auto vector_cast(const V * values, size_t count) {
  return std::vector< V >(values, values + count);
}
