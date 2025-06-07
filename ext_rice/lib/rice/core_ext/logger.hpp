class Logger {
  public:

  enum LEVEL { <%= ExtRice.config.log_levels.keys.map(&:upcase).join(', ') %> };

  static const std::string LEVELS[<%= ExtRice.config.log_levels.size %>];
  static size_t marker_i;
  static bool new_run;

  explicit Logger() {
    file.open("<%= ExtRice.config.log_path %>", std::ofstream::out | std::ofstream::app);
  }
  <%= no_copy :Logger %>

  ~Logger() {
    // no file.close, since global/static variables' destructors aren't called in DLL unload/exit
  }

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

const std::string Logger::LEVELS[] = { <%= ExtRice.config.log_levels.keys.map(&:upcase).map(&:quoted).join(', ') %> };
size_t Logger::marker_i = 0;
bool Logger::new_run = true;

auto logger = Logger();

<%- ExtRice.config.log_levels.each do |level, level_i| -%>
template < class... Args >
void log_<%= level %>(const Args & ...messages) {
  <%- if level_i >= ExtRice.config.log_level_i -%>
  logger.log< Args... >(messages..., Logger::LEVEL::<%= level.upcase %>);
  <%- end -%>
}

<%- end -%>
void log_mark() {
  log_error("mark: ", Logger::marker_i++);
}

template < class T >
void log_vector(const T vector[], size_t count, std::string_view prefix = "") {
  std::stringstream message;
  message << (prefix.size() ? prefix : "vector");
  for (size_t i = 0; i < count; ++i) {
    message << " (" << std::to_string(i) << ") " << std::to_string(vector[i]);
  }
  log_error(message.str());
}

template < class T >
void log_vector(const std::vector< T > & vector, std::string_view prefix = "") {
  log_vector< T >(vector.data(), vector.size(), prefix);
}
