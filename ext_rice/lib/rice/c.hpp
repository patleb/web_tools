namespace C {
  inline std::string timestamp() {
    std::chrono::system_clock::time_point now = std::chrono::system_clock::now();
    std::time_t time = std::chrono::system_clock::to_time_t(now);
    std::tm utc{}; gmtime_r(&time, &utc);
    std::chrono::duration<double> seconds = (now - std::chrono::system_clock::from_time_t(time)) + std::chrono::seconds(utc.tm_sec);
    std::string buffer("year-mo-dy hr:mn:sc.xxxxxx UTC");
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
  auto vector_cast(const std::vector< V > & values) {
    size_t size = values.size();
    std::vector< T > casts(size);
    for (size_t i = 0; i < size; ++i) {
      casts[i] = static_cast< T >(values[i]);
    }
    return casts;
  }

  template < class V, class T >
  auto vector_cast(const V * values, size_t size) {
    std::vector< T > casts(size);
    for (size_t i = 0; i < size; ++i) {
      casts[i] = static_cast< T >(values[i]);
    }
    return casts;
  }

  template <>
  auto vector_cast< std::string, char >(const std::vector< std::string > & values) {
    size_t size = values.size();
    size_t c_size = 0;
    for (size_t i = 0; i < size; ++i) {
      size_t count = values[i].size();
      if (count > c_size) c_size = count;
    }
    c_size += 1; // '\0'
    std::vector< char * > casts;
    for (size_t i = 0; i < size; ++i) {
      casts[i] = new char[c_size];
      strcpy(casts[i], values[i].c_str());
    }
    return casts;
  }

  void vector_free(const std::vector< char * > & values) {
    size_t size = values.size();
    for (size_t i = 0; i < size; ++i) {
      delete [] values[i];
    }
  }

  template <>
  auto vector_cast< char, std::string >(const char * values, size_t size) {
    std::vector< std::string > casts(size);
    for (size_t i = 0; i < size; ++i) {
      casts[i] = std::string(&values[i]);
    }
    return casts;
  }
}
