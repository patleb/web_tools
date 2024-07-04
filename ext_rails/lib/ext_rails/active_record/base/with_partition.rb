module ActiveRecord::Base::WithPartition
  extend ActiveSupport::Concern

  class UnsupportedPartitionBucket < ::StandardError; end
  class UnknownPartitionSize < ::StandardError; end
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

  DATE_PARTITION_BUCKETS = %i(month week day)
  DATE = /\d{4}_\d{2}_\d{2}$/
  NUMBER = /\d{19}$/ # support BIGINT

  prepended do
    class_attribute :partition_column, instance_accessor: false, instance_predicate: false
    class_attribute :partition_size, instance_accessor: false, instance_predicate: false
  end

  class_methods do
    def has_partition(column: :id, size: nil)
      self.partition_column = column
      self.partition_size = size
    end

    def partitioned?
      !!partition_column
    end

    def insert_all!(rows, **)
      partitioned? ? with_partition(rows){ super } : super
    end

    def insert_all(rows, **)
      partitioned? ? with_partition(rows){ super } : super
    end

    def upsert_all(rows, **)
      partitioned? ? with_partition(rows){ super } : super
    end

    def with_partition(rows, table = table_name, column: partition_column, size: partition_size)
      yield
    rescue MissingPartition
      rows.each{ |row| create_partition_for(row[column], table, size: size) }
      retry
    end

    def create_all_partitions(keys, table = table_name, size: partition_size)
      keys.each{ |key| create_partition_for(key, table, size: size) }
    end

    def drop_all_partitions(keys, table = table_name, size: partition_size)
      keys.each{ |key| drop_partition_for(key, table, size: size) }
    end

    def create_partition(name)
      create_partition_for(*partition_key_table(name))
    end

    def drop_partition(name)
      drop_partition_for(*partition_key_table(name))
    end

    def create_partition_for(key, table = table_name, size: partition_size)
      partition = partition_for(key, table, size: size)
      return if partitions(table).include? partition[:name]
      connection.exec_query(<<-SQL.strip_sql)
        CREATE TABLE #{partition[:name]} PARTITION OF #{table}
          FOR VALUES FROM ('#{partition[:from]}') TO ('#{partition[:to]}')
      SQL
      (@_partitions ||= {})[table] = nil
    rescue DuplicatePartition
      (@_partitions ||= {})[table] = nil
    end

    def drop_partition_for(key, table = table_name, size: partition_size)
      partition = partition_for(key, table, size: size)
      return if partitions(table).exclude? partition[:name]
      connection.exec_query("DROP TABLE IF EXISTS #{partition[:name]}")
      (@_partitions ||= {})[table] = nil
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

    def partition_empty?(name)
      connection.select_value("SELECT count(*) FROM (SELECT 1 FROM #{name} LIMIT 1) AS t") != 1
    end

    def partition_for(key, table = table_name, size: partition_size)
      case key
      when Integer
        size = size.to_i
        bucket = (key / size) * size
        from = bucket.to_s.rjust(19, '0')
        to = (bucket + size).to_s.rjust(19, '0')
      when Time, Date, DateTime
        raise UnsupportedPartitionBucket, "size: [#{size}]" unless size.to_sym.in? DATE_PARTITION_BUCKETS
        date = key.send("beginning_of_#{size}")
        from = date.strftime('%Y_%m_%d')
        to = (date + 1.send(size)).strftime('%Y_%m_%d')
      else
        raise UnsupportedPartitionBucket, "key: [#{key}]"
      end
      { name: "#{table}_#{from}", from: from, to: to }
    end

    private

    def partition_key_table(name)
      key_table = name.split(/_(#{DATE}|#{NUMBER})$/).reverse
      raise InvalidPartitionName, "name: [#{name}]" unless key_table.size == 2
      key, table = key_table
      [partition_bucket(key), table]
    end
  end
end
