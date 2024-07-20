class Tableless < ActiveRecord::Base
  class << self
    def load_schema
      # do nothing
    end

    def columns
      @columns ||= []
    end

    def column(name, sql_type = nil, default = nil, null = true)
      type = connection.send(:lookup_cast_type, sql_type.to_s)
      define_attribute(name.to_s, type)
      columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, type, sql_type.to_s, null)
    end

    def columns_hash
      @columns_hash ||= columns.map{ |column| [column.name, column] }.to_h
    end

    def column_names
      @column_names ||= columns.map(&:name)
    end

    def column_defaults
      @column_defaults ||= columns.each_with_object({}){ |column, memo| memo[column.name] = nil }
    end

    def attribute_types
      @attribute_types ||= columns.map{ |column| [column.name, lookup_attribute_type(column.type)] }.to_h
    end

    private

    def lookup_attribute_type(type)
      ActiveRecord::Type.lookup({ datetime: :time }[type] || type)
    end
  end

  def save(validate = true)
    validate ? valid? : true
  end
end
