require 'active_record/connection_adapters/abstract/schema_statements'

module ActiveRecord::ConnectionAdapters::SchemaStatements::WithUser
  def add_userstamps(table_name, options = {})
    add_belongs_to table_name, :creator, options
    add_belongs_to table_name, :updater, options
  end

  def remove_userstamps(table_name, options = {})
    remove_belongs_to table_name, :updater
    remove_belongs_to table_name, :creator
  end
end

ActiveRecord::ConnectionAdapters::SchemaStatements.include ActiveRecord::ConnectionAdapters::SchemaStatements::WithUser
