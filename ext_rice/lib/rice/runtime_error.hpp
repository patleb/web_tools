#define BACKTRACE std::stacktrace::current()
#define LOCATION std::source_location::current()

class RuntimeError : public std::exception {
  public:

  RuntimeError(std::string_view what_msg, const std::stacktrace & trace = BACKTRACE, const std::source_location & source = LOCATION):
    what_msg(what_msg),
    trace(std::to_string(trace)),
    source(source) {
  }

  const char * what() const throw() {
    return (
      std::string(source.file_name()) + ":"
        + std::to_string(source.line()) + ": "
        + what_msg + "\n"
        + trace
    ).c_str();
  }

  private:

  std::string what_msg;
  std::string trace;
  std::source_location source;
};
