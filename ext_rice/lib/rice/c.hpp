#define DOUBLE_SAFE_INT64 9007199254740991

namespace C {
  using std::string;
  using std::vector;

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
    return values;
  }

  template < class V, V >
  auto vector_cast(const V * values, size_t count) {
    return vector< V >(values, values + count);
  }

  template <>
  auto vector_cast< string, char >(const vector< string > & values) {
    size_t count = values.size();
    size_t max_size = 0;
    for (size_t i = 0; i < count; ++i) {
      size_t size = values[i].size();
      if (size > max_size) max_size = size;
    }
    max_size += 1; // '\0'
    vector< char * > casts;
    for (size_t i = 0; i < count; ++i) {
      casts[i] = new char[max_size];
      strcpy(casts[i], values[i].c_str());
    }
    return casts;
  }

  void vector_free(const vector< char * > & values) {
    size_t count = values.size();
    for (size_t i = 0; i < count; ++i) {
      delete [] values[i];
    }
  }

  template <>
  auto vector_cast< char, string >(const char * values, size_t count) {
    vector< string > casts(count);
    for (size_t i = 0; i < count; ++i) {
      casts[i] = string(&values[i]);
    }
    return casts;
  }
}
