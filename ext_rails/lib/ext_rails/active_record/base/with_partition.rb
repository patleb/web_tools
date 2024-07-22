module ActiveRecord::Base::WithPartition
  extend ActiveSupport::Concern

  class UnsupportedPartitionBucket < ::StandardError; end
  class InvalidPartitionColumn < ::StandardError; end
  class InvalidPartitionName < ::StandardError; end

  class DuplicatePartition < ActiveRecord::StatementInvalid
    def self.===(exception)
      exception.message.match? /PG::DuplicateTable/
    end
  end

  class MissingPartition < ActiveRecord::StatementInvalid
    def self.===(exception)
      exception.message.match? /no partition of relation "\w+" found for row/
    end
  end

  DATE_PARTITION_BUCKETS = %i(year quarter month week day)
  DATE = /\d{4}_\d{2}_\d{2}$/
  NUMBER = /\d{19}$/ # support BIGINT
  COLUMN_VALUE = /Partition key of the failing row contains \((\w+)\) = \(([\d :.-]+)\)/i

  prepended do
    class_attribute :partition_size, instance_accessor: false, instance_predicate: false
  end

  class_methods do
    def insert_all!(rows, **)
      partition_size ? with_partition(rows){ super } : super
    end

    def insert_all(rows, **)
      partition_size ? with_partition(rows){ super } : super
    end

    def upsert_all(rows, **)
      partition_size ? with_partition(rows){ super } : super
    end

    def with_partition(rows, table = table_name, size: partition_size)
      yield
    rescue MissingPartition => error
      column, value = error.message.match(COLUMN_VALUE).captures
      column = column.to_sym
      if rows.dig(0, column)
        rows.each{ |row| create_partition_for(row[column], table, size: size) }
      elsif primary_key && primary_key.to_sym == column
        value = value.to_i
        (value...(value + rows.size)).each{ |key| create_partition_for(key, table, size: size) }
      else
        raise InvalidPartitionColumn, "column: [#{column}], value: [#{value}]"
      end
      retry
    end

    def create_all_partitions(keys, table = table_name, size: db_partition_size(table))
      keys.each{ |key| create_partition_for(key, table, size: size) }
    end

    def drop_all_partitions(keys, table = table_name, size: db_partition_size(table))
      keys.each{ |key| drop_partition_for(key, table, size: size) }
    end

    def drop_all_partitions!(table = table_name)
      partitions(table).each do |name|
        connection.exec_query("DROP TABLE IF EXISTS #{name}")
      end
      connection.exec_query("TRUNCATE TABLE #{table} RESTART IDENTITY")
      reset_partitions(table)
    end

    def create_partition(name)
      create_partition_for(*partition_key_table(name))
    end

    def drop_partition(name)
      drop_partition_for(*partition_key_table(name))
    end

    def create_partition_for(key, table = table_name, size: db_partition_size(table))
      partition = partition_for(key, table, size: size)
      return if partitions(table).include? partition[:name]
      connection.exec_query(<<-SQL.strip_sql)
        CREATE TABLE #{partition[:name]} PARTITION OF #{table}
          FOR VALUES FROM ('#{partition[:from]}') TO ('#{partition[:to]}')
      SQL
      reset_partitions(table)
    rescue DuplicatePartition
      reset_partitions(table)
    end

    def drop_partition_for(key, table = table_name, size: db_partition_size(table))
      partition = partition_for(key, table, size: size)
      return if partitions(table).exclude? partition[:name]
      connection.exec_query("DROP TABLE IF EXISTS #{partition[:name]}")
      reset_partitions(table)
    end

    def partitions(table = table_name)
      (@_partitions ||= {})[table] ||= begin
        connection.select_values(<<-SQL.strip_sql)
          SELECT inhrelid::regclass FROM pg_catalog.pg_inherits WHERE inhparent = '#{table}'::regclass ORDER BY 1
        SQL
      end
    end

    def partitions_buckets(table = table_name)
      partitions(table).map{ |name| partition_bucket(name) }
    end

    def partition_bucket(name)
      if (date = name[DATE])
        Time.find_zone('UTC').parse(date.dasherize).utc
      else
        name[NUMBER].to_i
      end
    end

    def partition_key_table(name)
      key_table = name.split(/_(#{DATE}|#{NUMBER})$/).reverse
      raise InvalidPartitionName, "name: [#{name}]" unless key_table.size == 2
      key, table = key_table
      [partition_bucket(key), table]
    end

    def partition_empty?(name)
      connection.select_value("SELECT count(*) FROM (SELECT 1 FROM #{name} LIMIT 1) AS t") != 1
    end

    def partition_for(key, table = table_name, size: db_partition_size(table))
      case key
      when Integer
        size = size.to_i
        bucket = (key / size) * size
        from = bucket.to_s.rjust(19, '0')
        to = (bucket + size).to_s.rjust(19, '0')
      when Time, Date, DateTime
        raise UnsupportedPartitionBucket, "size: [#{size}]" unless size.to_sym.in? DATE_PARTITION_BUCKETS
        time = key.public_send("beginning_of_#{size}")
        from = time.date_tag
        to = (time + 1.public_send(size)).date_tag
      else
        raise UnsupportedPartitionBucket, "key: [#{key}]"
      end
      { name: "#{table}_#{from}", from: from, to: to } # 'from' is inclusive, 'to' is exclusive
    end

    def db_partition_size(table = table_name)
      ExtRails.config.db_partitions[table] || partition_size
    end

    private

    def reset_partitions(table)
      (@_partitions ||= {})[table] = nil
    end
  end
end
