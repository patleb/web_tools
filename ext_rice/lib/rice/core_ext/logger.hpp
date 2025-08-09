<%- levels = ExtRice.config.log_levels -%>
class Logger {
  public:

  enum LEVEL { <%= ExtRice.config.log_levels.keys.map(&:upcase).join(', ') %> };

  constexpr static std::string LEVELS[<%= levels.size %>] = { <%= levels.keys.map(&:upcase).map(&:quoted).join(', ') %> };
  inline static size_t marker_i = 0;
  inline static bool new_run = true;

  explicit Logger() { file.open("<%= ExtRice.config.log_path %>", std::ofstream::out | std::ofstream::app); }
  <%= no_copy :Logger %>
  ~Logger() {} // no file.close, since global/static variables' destructors aren't called in DLL unload/exit

  // Parameter Pack: https://www.scs.stanford.edu/~dm/blog/param-pack.html
  template < class... Args >
  void log(const Args & ...messages, const LEVEL level) {
    <%- if Rails.env.local? -%>
    if (new_run) { new_run = false; file << std::endl; }
    <%- end -%>
    file << "[" << C::timestamp() << "][" << LEVELS[level] << "]: ";
    (file << ... << std::format("{}", messages));
    file << std::endl;
  }

  private:

  std::ofstream file;
};

inline auto logger = Logger();

<%- ExtRice.config.log_levels.each do |level, level_i| -%>
template < class... Args >
inline void log_<%= level %>(const Args & ...messages) {
  <%- if level_i >= ExtRice.config.log_level_i -%>
  logger.log< Args... >(messages..., Logger::LEVEL::<%= level.upcase %>);
  <%- end -%>
}

<%- end -%>
inline void log_mark() {
  log_error("mark: ", Logger::marker_i++);
}

template < class T >
inline void log_vector(std::string_view prefix, const T vector[], size_t count) {
  std::stringstream message;
  message << prefix;
  for (size_t i = 0; i < count; ++i) {
    message << " (" << std::to_string(i) << ") " << std::to_string(vector[i]);
  }
  log_error(message.str());
}

template < class T >
inline void log_vector(std::string_view prefix, const std::vector< T > & vector) {
  log_vector< T >(prefix, vector.data(), vector.size());
}
