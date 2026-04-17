namespace MatIO {
  using std::string;
  using std::vector;

  enum class Type {
    <%- template[:matio].each do |TENSOR, MAT_C_TYPE| -%>
    TENSOR = MAT_C_TYPE,
    <%- end -%>
    String = MAT_C_CHAR
  };

  class Base {
    public:

    mat_t * file = NULL;

    Base() = default;

    explicit Base(mat_t * file):
      file(file) {
    }

    protected:

    static void check_status(int code, CONTEXT(trace, source)) {
      string msg;
      switch (code) {
      case MATIO_E_NO_ERROR: return; // 0
      case MATIO_E_UNKNOWN_ERROR:                       msg = "UNKNOWN_ERROR ["                       S(MATIO_E_UNKNOWN_ERROR) "]";                       break; // 1
      case MATIO_E_GENERIC_READ_ERROR:                  msg = "GENERIC_READ_ERROR ["                  S(MATIO_E_GENERIC_READ_ERROR) "]";                  break; // 2
      case MATIO_E_GENERIC_WRITE_ERROR:                 msg = "GENERIC_WRITE_ERROR ["                 S(MATIO_E_GENERIC_WRITE_ERROR) "]";                 break; // 3
      case MATIO_E_INDEX_TOO_BIG:                       msg = "INDEX_TOO_BIG ["                       S(MATIO_E_INDEX_TOO_BIG) "]";                       break; // 4
      case MATIO_E_FILE_FORMAT_VIOLATION:               msg = "FILE_FORMAT_VIOLATION ["               S(MATIO_E_FILE_FORMAT_VIOLATION) "]";               break; // 5
      case MATIO_E_FAIL_TO_IDENTIFY:                    msg = "FAIL_TO_IDENTIFY ["                    S(MATIO_E_FAIL_TO_IDENTIFY) "]";                    break; // 6
      case MATIO_E_BAD_ARGUMENT:                        msg = "BAD_ARGUMENT ["                        S(MATIO_E_BAD_ARGUMENT) "]";                        break; // 7
      case MATIO_E_OUTPUT_BAD_DATA:                     msg = "OUTPUT_BAD_DATA ["                     S(MATIO_E_OUTPUT_BAD_DATA) "]";                     break; // 8
      case MATIO_E_OPERATION_NOT_SUPPORTED:             msg = "OPERATION_NOT_SUPPORTED ["             S(MATIO_E_OPERATION_NOT_SUPPORTED) "]";             break; // 13
      case MATIO_E_OUT_OF_MEMORY:                       msg = "OUT_OF_MEMORY ["                       S(MATIO_E_OUT_OF_MEMORY) "]";                       break; // 14
      case MATIO_E_BAD_VARIABLE_NAME:                   msg = "BAD_VARIABLE_NAME ["                   S(MATIO_E_BAD_VARIABLE_NAME) "]";                   break; // 15
      case MATIO_E_OPERATION_PROHIBITED_IN_WRITE_MODE:  msg = "OPERATION_PROHIBITED_IN_WRITE_MODE ["  S(MATIO_E_OPERATION_PROHIBITED_IN_WRITE_MODE) "]";  break; // 16
      case MATIO_E_OPERATION_PROHIBITED_IN_READ_MODE:   msg = "OPERATION_PROHIBITED_IN_READ_MODE ["   S(MATIO_E_OPERATION_PROHIBITED_IN_READ_MODE) "]";   break; // 17
      case MATIO_E_WRITE_VARIABLE_DOES_NOT_EXIST:       msg = "WRITE_VARIABLE_DOES_NOT_EXIST ["       S(MATIO_E_WRITE_VARIABLE_DOES_NOT_EXIST) "]";       break; // 18
      case MATIO_E_READ_VARIABLE_DOES_NOT_EXIST:        msg = "READ_VARIABLE_DOES_NOT_EXIST ["        S(MATIO_E_READ_VARIABLE_DOES_NOT_EXIST) "]";        break; // 19
      case MATIO_E_FILESYSTEM_COULD_NOT_OPEN:           msg = "FILESYSTEM_COULD_NOT_OPEN ["           S(MATIO_E_FILESYSTEM_COULD_NOT_OPEN) "]";           break; // 20
      case MATIO_E_FILESYSTEM_COULD_NOT_OPEN_TEMPORARY: msg = "FILESYSTEM_COULD_NOT_OPEN_TEMPORARY [" S(MATIO_E_FILESYSTEM_COULD_NOT_OPEN_TEMPORARY) "]"; break; // 21
      case MATIO_E_FILESYSTEM_COULD_NOT_REOPEN:         msg = "FILESYSTEM_COULD_NOT_REOPEN ["         S(MATIO_E_FILESYSTEM_COULD_NOT_REOPEN) "]";         break; // 22
      case MATIO_E_BAD_OPEN_MODE:                       msg = "BAD_OPEN_MODE ["                       S(MATIO_E_BAD_OPEN_MODE) "]";                       break; // 23
      case MATIO_E_FILESYSTEM_ERROR_ON_CLOSE:           msg = "FILESYSTEM_ERROR_ON_CLOSE ["           S(MATIO_E_FILESYSTEM_ERROR_ON_CLOSE) "]";           break; // 24
      default:                                          msg = "unknown error code [" S(code) "]";
      }
      throw RuntimeError(msg, trace, source);
    }
  };

  inline matio_classes type_id(const Tensor::NType & values) {
    switch (values.index()) {
    <%- template[:matio].each_value.with_index do |MAT_C_TYPE, I| -%>
    case I: return MAT_C_TYPE;
    <%- end -%>
    default: throw TypeError();
    }
  }

  inline matio_classes type_id(std::string_view name) {
    <%- template[:matio].each do |TENSOR, MAT_C_TYPE| -%>
    if (name == "<%= @TENSOR %>") return MAT_C_TYPE;
    <%- end -%>
    if (name == "String") return MAT_C_CHAR;
    throw TypeError();
  }

  inline Type type(matio_classes id) {
    switch (id) {
    <%- template[:matio].each do |TENSOR, MAT_C_TYPE| -%>
    case MAT_C_TYPE: return MatIO::Type::TENSOR;
    <%- end -%>
    case MAT_C_CHAR: return MatIO::Type::String;
    }
    throw TypeError();
  }
}
