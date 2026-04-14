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
inline auto vector_concat(std::initializer_list< std::vector< T >> vectors) {
  size_t count = 0;
  for (auto && v : vectors) count += v.size();
  std::vector< T > result(count); // gcc 15 --> result.append_range(v)
  for (auto && v : vectors) result.insert(result.end(), v.cbegin(), v.cend());
  return result;
}

template < class T >
inline auto & vector_concat(std::vector< T > & values, std::initializer_list< std::vector< T >> vectors) {
  size_t count = 0;
  for (auto && v : vectors) count += v.size();
  values.reserve(values.size() + count);
  for (auto && v : vectors) values.insert(values.end(), v.cbegin(), v.cend());
  return values;
}

template < class V, class T >
inline auto vector_cast(const std::vector< V > & values) {
  size_t count = values.size();
  std::vector< T > casts(count);
  for (size_t i = 0; i < count; ++i) {
    casts[i] = static_cast< T >(values[i]);
  }
  return casts;
}

template < class V, class T >
inline auto vector_cast(const V * values, size_t count) {
  std::vector< T > casts(count);
  for (size_t i = 0; i < count; ++i) {
    casts[i] = static_cast< T >(values[i]);
  }
  return casts;
}

template < class V, V >
inline auto vector_cast(const std::vector< V > & values) {
  return std::vector< V >(values);
}

template < class V, V >
inline auto vector_cast(const V * values, size_t count) {
  return std::vector< V >(values, values + count);
}

template < class V, class T >
inline std::string string_cast(const char * bytes, size_t count) = delete;

template <>
inline std::string string_cast< char16_t, char >(const char * bytes, size_t count) {
  if (count == 0 || bytes == nullptr) return {};
  uint8_t b0, b1;
  size_t offset = 0;
  bool little_endian = true;
  if (count >= 2) {
    b0 = static_cast< uint8_t >(bytes[0]);
    b1 = static_cast< uint8_t >(bytes[1]);
    if (b0 == 0xFF && b1 == 0xFE) {
      offset = 2;
    } else if (b0 == 0xFE && b1 == 0xFF) {
      offset = 2;
      little_endian = false;
    }
  }
  if (offset >= count) return {};
  auto size = count - offset;
  if (size % 2 != 0) size--; // incomplete pair
  std::string utf8;
  utf8.reserve(size + size / 2);
  for (size_t i = offset; i + 1 < count; i += 2) {
    b0 = static_cast< uint8_t >(bytes[i]);
    b1 = static_cast< uint8_t >(bytes[i + 1]);
    char16_t c = little_endian ? (b1 << 8 | b0) : (b0 << 8 | b1);
    if (c < 0x80) {                          // 1 byte
      utf8.push_back(static_cast< char >(c));
    } else if (c < 0x800) {                  // 2 bytes
      utf8.push_back(0xC0 | (c >> 6));
      utf8.push_back(0x80 | (c & 0x3F));
    } else if (c < 0xD800 || c > 0xDFFF) {   // 3 bytes
      utf8.push_back(0xE0 | (c >> 12));
      utf8.push_back(0x80 | ((c >> 6) & 0x3F));
      utf8.push_back(0x80 | (c & 0x3F));
    } else if (c >= 0xD800 && c <= 0xDBFF) { // high surrogate
      if (i + 3 < count) {
        b0 = static_cast< uint8_t >(bytes[i + 2]);
        b1 = static_cast< uint8_t >(bytes[i + 3]);
        char16_t low = little_endian ? (b1 << 8 | b0) : (b0 << 8 | b1);
        if (low >= 0xDC00 && low <= 0xDFFF) {
          uint32_t codepoint = 0x10000 + ((c - 0xD800) << 10) + (low - 0xDC00);
          utf8.push_back(0xF0 | (codepoint >> 18));
          utf8.push_back(0x80 | ((codepoint >> 12) & 0x3F));
          utf8.push_back(0x80 | ((codepoint >> 6)  & 0x3F));
          utf8.push_back(0x80 | (codepoint & 0x3F));
          i += 2; // skip low surrogate
          continue;
        }
      }
      utf8.append("�");
    } else { // lone low surrogate
      utf8.append("�");
    }
  }
  return utf8;
}
