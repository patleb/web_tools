#define DOUBLE_SAFE_INT64 9007199254740991
#define S(value) + std::to_string((value)) +
#define G_NULL   0
#define G_DOUBLE 1
#define G_INT64  2
#define G_UINT64 3
#define G_STRING 4

typedef long long int64_t2;
typedef unsigned long long uint64_t2;

using Vstring = std::vector< std::string >;
using Ostring = std::optional< std::string >;
using Vint = std::vector< int >;
using Oint = std::optional< int >;
using Vbool = std::vector< bool >;
using Obool = std::optional< bool >;
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
using GType = std::variant< std::monostate, <%= compile_vars[:generic_types].keys.join(', ') %>, std::string >;

constexpr auto nil = std::nullopt;
constexpr auto null = std::monostate{};

bool is_null(const GType & value) {
  return value.index() == 0;
}

template < class T >
auto g_cast(const GType & value = null) {
  switch (value.index()) {
  case G_NULL:   return static_cast< T >(0);
  case G_DOUBLE: return static_cast< T >(std::get< G_DOUBLE >(value));
  case G_INT64:  return static_cast< T >(std::get< G_INT64 >(value));
  case G_UINT64: return static_cast< T >(std::get< G_UINT64 >(value));
  default: throw RuntimeError("invalid GType");
  }
}
<%- compile_vars[:generic_types].each do |type, generic_type| -%>

auto g_cast(<%= type %> value) {
  return static_cast< <%= generic_type %> >(value);
}
<%- end -%>

namespace C {
  using std::string;
  using std::vector;

  const double NaN = std::numeric_limits< double >::quiet_NaN(); // std::isnan(double)
  const double Inf = std::numeric_limits< double >::infinity();  // std::isinf(double) --> true also for -Inf, use (double == -C::INF)

  inline auto timestamp() {
    std::chrono::system_clock::time_point now = std::chrono::system_clock::now();
    std::time_t time = std::chrono::system_clock::to_time_t(now);
    std::tm utc{}; gmtime_r(&time, &utc);
    std::chrono::duration<double> seconds = (now - std::chrono::system_clock::from_time_t(time)) + std::chrono::seconds(utc.tm_sec);
    string buffer("year-mo-dy hr:mn:sc.xxxxxx UTC");
    sprintf(&buffer.front(), "%04d-%02d-%02d %02d:%02d:%09.6f UTC",
      utc.tm_year + 1900,
      (uint8_t)(utc.tm_mon + 1),
      (uint8_t)utc.tm_mday,
      (uint8_t)utc.tm_hour,
      (uint8_t)utc.tm_min,
      seconds.count()
    );
    return buffer;
  }

  template < class T >
  auto vector_concat(std::initializer_list< vector< T >> vectors) {
    size_t count = 0;
    for (auto && v : vectors) count += v.size();
    vector< T > result(count); // gcc 15 --> result.append_range(v)
    for (auto && v : vectors) result.insert(result.end(), v.cbegin(), v.cend());
    return result;
  }

  template < class T >
  auto & vector_concat(vector< T > & values, std::initializer_list< vector< T >> vectors) {
    size_t count = 0;
    for (auto && v : vectors) count += v.size();
    values.reserve(values.size() + count);
    for (auto && v : vectors) values.insert(values.end(), v.cbegin(), v.cend());
    return values;
  }

  template < class V, class T >
  auto vector_cast(const vector< V > & values) {
    size_t count = values.size();
    vector< T > casts(count);
    for (size_t i = 0; i < count; ++i) {
      casts[i] = static_cast< T >(values[i]);
    }
    return casts;
  }

  template < class V, class T >
  auto vector_cast(const V * values, size_t count) {
    vector< T > casts(count);
    for (size_t i = 0; i < count; ++i) {
      casts[i] = static_cast< T >(values[i]);
    }
    return casts;
  }

  template < class V, V >
  auto vector_cast(const vector< V > & values) {
    return vector< V >(values);
  }

  template < class V, V >
  auto vector_cast(const V * values, size_t count) {
    return vector< V >(values, values + count);
  }
}
