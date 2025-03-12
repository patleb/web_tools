#define THROW_ERROR(msg) throw RuntimeError((msg), __FILE__, __LINE__, std::to_string(std::stacktrace::current()))

class RuntimeError : public std::exception {
  public:

  RuntimeError(const char * what_msg, const char * file, int line, const std::string & stacktrace):
    RuntimeError(std::string(what_msg), file, line, stacktrace) {
  }

  RuntimeError(const std::string & what_msg, const char * file, int line, const std::string & stacktrace):
    what_msg(what_msg),
    file(file),
    line(line),
    stacktrace(stacktrace) {
  }

  const char * what() const throw() {
    return (file + ":" + std::to_string(line) + ": " + what_msg + "\n" + stacktrace).c_str();
  }

  private:

  std::string what_msg;
  std::string stacktrace;
  std::string file;
  int line;
};
