require 'active_record/connection_adapters/abstract/schema_statements'

module ActiveRecord::ConnectionAdapters::SchemaStatements::WithUser
  def add_userstamps(table_name, **)
    add_belongs_to(table_name, :creator, **)
    add_belongs_to(table_name, :updater, **)
  end

  def remove_userstamps(table_name, **)
    remove_belongs_to table_name, :updater
    remove_belongs_to table_name, :creator
  end

  def add_creator(table_name, **)
    add_belongs_to(table_name, :creator, **)
  end

  def remove_creator(table_name, **)
    remove_belongs_to table_name, :creator
  end

  def add_updater(table_name, **)
    add_belongs_to(table_name, :updater, **)
  end

  def remove_updater(table_name, **)
    remove_belongs_to table_name, :updater
  end
end

ActiveRecord::ConnectionAdapters::SchemaStatements.include ActiveRecord::ConnectionAdapters::SchemaStatements::WithUser
