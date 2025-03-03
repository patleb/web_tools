#include <string>
#include <chrono>

namespace C {
  inline std::string timestamp() {
    std::chrono::system_clock::time_point now = std::chrono::system_clock::now();
    std::time_t time = std::chrono::system_clock::to_time_t(now);
    std::tm utc{}; gmtime_r(&time, &utc);
    std::chrono::duration<double> seconds = (now - std::chrono::system_clock::from_time_t(time)) + std::chrono::seconds(utc.tm_sec);
    std::string buffer("year-mo-dy hr:mn:sc.xxxxxx UTC");
    sprintf(&buffer.front(), "%04d-%02d-%02d %02d:%02d:%09.6f UTC",
      utc.tm_year + 1900,
      utc.tm_mon + 1,
      utc.tm_mday,
      utc.tm_hour,
      utc.tm_min,
      seconds.count()
    );
    return buffer;
  }

  template<class K, class V>
  auto multimap_keys(const std::multimap< K, V >& multimap) {
    std::vector< K > list;
    for (auto itr = multimap.begin(); itr != multimap.end(); itr++)
      list.push_back(itr->first);
    return list;
  }

  template<class K, class V>
  auto multimap_values(const std::multimap< K, V >& multimap) {
    std::vector< V > list;
    for (auto itr = multimap.begin(); itr != multimap.end(); itr++)
      list.push_back(itr->second);
    return list;
  }

  template<class V>
  auto set_to_vector(const std::set< V >& set) {
    std::vector< V > list;
    list.assign(set.begin(), set.end());
    return list;
  }
}
