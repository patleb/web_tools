class Logger {
  public:

  enum LEVEL { <%= ExtRice.config.log_levels.keys.map(&:upcase).join(', ') %> };
  static const std::string LEVELS[<%= ExtRice.config.log_levels.size %>];

  explicit Logger() {
    file.open("<%= ExtRice.config.log_path %>", std::ofstream::out | std::ofstream::app);
  }

  // non-copyable
  Logger(const Logger&) = delete;
  Logger& operator=(const Logger&) = delete;

  ~Logger() {
    // no file.close, since global/static variables' destructors aren't called in DLL unload/exit
  }

  template<class... Args>
  void log(const Args& ...messages, const LEVEL level) {
    file << "[" << C::timestamp() << "][" << LEVELS[level] << "]: ";
    (file << ... << messages);
    file << std::endl;
  }

  private:

  std::ofstream file;
};

const std::string Logger::LEVELS[] = { <%= ExtRice.config.log_levels.keys.map(&:upcase).map(&:quoted).join(', ') %> };

auto logger = Logger();

<%- ExtRice.config.log_levels.each do |level, level_i| -%>
template<class... Args>
void log_<%= level %>(const Args& ...messages) {
  <%- if level_i >= ExtRice.config.log_level_i -%>
  logger.log<Args...>(messages..., Logger::LEVEL::<%= level.upcase %>);
  <%- end -%>
}

<%- end -%>
