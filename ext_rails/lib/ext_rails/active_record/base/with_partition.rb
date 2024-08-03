module ActiveRecord::Base::WithPartition
  extend ActiveSupport::Concern

  class UnsupportedPartitionBucket < ::StandardError; end
  class InvalidPartitionColumn < ::StandardError; end

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

    def partition_size(table = table_name)
      ExtRails.config.db_partitions[table]
    end

    def with_partition(rows)
      yield
    rescue MissingPartition => error
      column, value = error.message.match(COLUMN_VALUE).captures
      column = column.to_sym
      if rows.dig(0, column)
        rows.each{ |row| create_partition(row[column]) }
      elsif primary_key && primary_key.to_sym == column
        value = value.to_i
        (value...(value + rows.size)).each{ |key| create_partition(key) }
      else
        raise InvalidPartitionColumn, "column: [#{column}], value: [#{value}]"
      end
      retry
    end

    def create_all_partitions(keys, **)
      Array.wrap(keys).each{ |key| create_partition(key, **) }
    end

    def drop_all_partitions!(keys, **)
      drop_all_partitions(keys, **, force: true)
    end

    def drop_all_partitions(keys, **)
      Array.wrap(keys).each{ |key| drop_partition(key, **) }
    end

    def create_partition(key = nil, table: table_name, from: nil, to: nil)
      partition = partition_for(key, table, from: from, to: to)
      return if partitions(table).include? partition[:name]
      connection.exec_query(<<-SQL.strip_sql)
        CREATE TABLE #{partition[:name]} PARTITION OF #{table}
          FOR VALUES FROM ('#{partition[:from]}') TO ('#{partition[:to]}')
      SQL
      reset_partitions(table)
    rescue DuplicatePartition
      reset_partitions(table)
    end

    def drop_partition!(*, **)
      drop_all_partitions!(*, **, force: true)
    end

    def drop_partition(key = nil, table: table_name, from: nil, to: nil, force: false)
      name = partition_for(key, table, from: from, to: to)[:name]
      return if !force && partition_empty?(name)
      return if partitions(table).exclude?(name)
      connection.exec_query("DROP TABLE IF EXISTS #{name}")
      reset_partitions(table)
    end

    def partitions!(table = table_name)
      connection.select_values(<<-SQL.strip_sql)
        SELECT inhrelid::regclass FROM pg_catalog.pg_inherits WHERE inhparent = '#{table}'::regclass ORDER BY 1
      SQL
    end

    def partitions(table = table_name)
      (@@partitions ||= {})[table] ||= partitions!(table)
    end

    def partitions_buckets(table = table_name)
      partitions(table).map{ |name| partition_bucket(name) }
    end

    def partition_bucket(name)
      if (date = name[DATE])
        Time.parse_utc(date.dasherize)
      else
        name[NUMBER].to_i
      end
    end

    def partition_empty?(name)
      connection.select_value("SELECT count(*) FROM (SELECT 1 FROM #{name} LIMIT 1) AS t") != 1
    end

    def _drop_all_partitions!(table = table_name)
      partitions(table).each do |name|
        connection.exec_query("DROP TABLE IF EXISTS #{name}")
      end
      connection.exec_query("TRUNCATE TABLE #{table} RESTART IDENTITY")
      reset_partitions(table)
    end

    private

    def partition_for(key, table, size: partition_size(table), from: nil, to: nil)
      case key
      when Integer
        bucket = (key / size) * size
        from = bucket.to_s.rjust(19, '0')
        to = (bucket + size).to_s.rjust(19, '0')
      when Time, Date, DateTime
        raise UnsupportedPartitionBucket, "size: [#{size}]" unless DATE_PARTITION_BUCKETS.include? size.to_sym
        bucket = key.public_send("beginning_of_#{size}")
        from = bucket.date_tag
        to = (bucket + 1.public_send(size)).date_tag
      when String
        return partition_for(partition_bucket(key), table)
      when nil
        raise UnsupportedPartitionBucket, "from: [#{from}], to: [#{to}]" unless from.is_a?(String) && to.is_a?(String)
      else
        raise UnsupportedPartitionBucket, "key: [#{key}]"
      end
      { name: "#{table}_#{from}", from: from, to: to } # 'from' is inclusive, 'to' is exclusive
    end

    def reset_partitions(table)
      (@@partitions ||= {})[table] = nil
    end
  end
end
