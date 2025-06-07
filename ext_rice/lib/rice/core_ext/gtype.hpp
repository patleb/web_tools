#define G_NULL   0
#define G_DOUBLE 1
#define G_INT64  2
#define G_UINT64 3
#define G_STRING 4

constexpr auto null = nullstate{};

using GType = std::variant< nullstate, <%= compile_vars[:generic_types].values.uniq.join(', ') %>, std::string >;

bool is_null(const GType & value) {
  return value.index() == 0;
}

template < class T >
auto g_cast(const GType & value = null) {
  switch (value.index()) {
  case G_NULL:   return static_cast< T >(0);
  case G_DOUBLE: return static_cast< T >(std::get< G_DOUBLE >(value));
  case G_INT64:  return static_cast< T >(std::get< G_INT64 >(value));
  case G_UINT64: return static_cast< T >(std::get< G_UINT64 >(value));
  default: throw RuntimeError("invalid GType");
  }
}

template < float >
auto g_cast(const GType & value = null) {
  switch (value.index()) {
  case G_NULL:   return static_cast< float >(Float::nan);
  case G_DOUBLE: return static_cast< float >(std::get< G_DOUBLE >(value));
  case G_INT64:  return static_cast< float >(std::get< G_INT64 >(value));
  case G_UINT64: return static_cast< float >(std::get< G_UINT64 >(value));
  default: throw RuntimeError("invalid GType");
  }
}

template < double >
auto g_cast(const GType & value = null) {
  switch (value.index()) {
  case G_NULL:   return Float::nan;
  case G_DOUBLE: return std::get< G_DOUBLE >(value);
  case G_INT64:  return static_cast< double >(std::get< G_INT64 >(value));
  case G_UINT64: return static_cast< double >(std::get< G_UINT64 >(value));
  default: throw RuntimeError("invalid GType");
  }
}
<%- compile_vars[:generic_types].each do |type, generic_type| -%>

auto g_cast(const O<%= type %> & value) {
  <%- case type -%>
  <%- when 'double' -%>
  return value ? *value : Float::nan;
  <%- when 'float' -%>
  return value ? static_cast< double >(*value) : Float::nan;
  <%- else -%>
  return static_cast< <%= generic_type %> >(value ? *value : 0);
  <%- end -%>
}

auto g_cast(<%= type %> value) {
  <%- if type == 'double' -%>
  return value;
  <%- else -%>
  return static_cast< <%= generic_type %> >(value);
  <%- end -%>
}
<%- end -%>
