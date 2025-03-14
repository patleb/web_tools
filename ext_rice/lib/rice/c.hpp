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

  template < class T, class V >
  auto cast(const std::vector< V > & values) {
    std::vector< T > casts(values.size());
    for (size_t i = 0; i < values.size(); ++i) {
      casts[i] = static_cast< T >(values[i]);
    }
    return casts;
  }

  template <>
  auto cast< const char *, std::string >(const std::vector< std::string > & values) {
    std::vector< const char * > casts(values.size());
    for (size_t i = 0; i < values.size(); ++i) {
      casts[i] = values[i].c_str();
    }
    return casts;
  }
}
