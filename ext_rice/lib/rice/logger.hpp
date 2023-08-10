#include <fstream>

class Logger {
  public:

  enum Level { <%= ExtRice.config.log_levels.keys.map(&:upcase).join(', ') %> };
  static const std::string LEVELS[<%= ExtRice.config.log_levels.size %>];

  explicit Logger() {
    file.open("<%= ExtRice.config.log_path %>", std::ofstream::out | std::ofstream::app);
  }

  ~Logger() {
    // no file.close, since global/static variables' destructors aren't called in DLL unload/exit
  }

  // non-copyable
  Logger(const Logger&) = delete;
  Logger& operator=(const Logger&) = delete;

  template<class... Args>
  void log(const Args& ...messages, const Level level) {
    (file << "[" << C::timestamp() << "]" << "[" << LEVELS[level] << "]: " << ... << messages) << std::endl;
  }

  private:

  std::ofstream file;
};

const std::string Logger::LEVELS[] = { <%= ExtRice.config.log_levels.keys.map{ |level| %{"#{level.upcase}"} }.join(', ') %> };

auto logger = Logger();

<%- ExtRice.config.log_levels.each do |level, level_i| -%>

  template<class... Args>
  void log_<%= level %>(const Args& ...messages) {
    <%- if level_i >= ExtRice.config.log_level_i -%>
      (logger.log<Args>(messages, Logger::Level::<%= level.upcase %>), ...);
    <%- end -%>
  }
<%- end -%>
