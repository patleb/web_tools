require 'active_record/connection_adapters/postgresql/schema_statements'

module ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements::WithTypeMap
  def type_to_sql(type, limit: nil, precision: nil, scale: nil, array: nil, **)
    case type.to_s
    when 'interval'
      case precision
      when nil;  "interval"
      when 0..6; "interval(#{precision})"
      else raise(ActiveRecordError, "No interval type has precision of #{precision}. The allowed range of precision is from 0 to 6")
      end
    else
      super
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements.prepend ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements::WithTypeMap
