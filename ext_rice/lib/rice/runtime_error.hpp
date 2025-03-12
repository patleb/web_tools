#define THROW_ERROR(msg) throw RuntimeError((msg), __FILE__, __LINE__)

class RuntimeError : public std::exception {
  public:

  RuntimeError(const char * what_msg, const char * file, int line):
    RuntimeError(std::string(what_msg), file, line) {
  }

  RuntimeError(const std::string & what_msg, const char * file, int line):
    what_msg(what_msg),
    file(file),
    line(line) {
  }

  const char * what() const throw() {
    return (file + ":" + std::to_string(line) + ": " + what_msg).c_str();
  }

  private:

  std::string what_msg;
  std::string file;
  int line;
};
