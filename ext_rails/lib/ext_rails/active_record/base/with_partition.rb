module ActiveRecord::Base::WithPartition
  extend ActiveSupport::Concern

  class UnsupportedPartitionBucket < ::StandardError; end

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

  TIME_PARTITION_BUCKETS = %i(month week day)

  class_methods do
    def with_partition(attributes, table = table_name, column:, **options)
      yield
    rescue MissingPartition
      attributes.each{ |row| create_partition(row[column], table, **options) }
      retry
    end

    def create_partition(key, table = table_name, **options)
      partition = partition_for(key, table, **options)
      return if partitions(table).include? partition[:name]
      connection.exec_query(<<-SQL.strip_sql)
        CREATE TABLE #{partition[:name]} PARTITION OF #{table}
          FOR VALUES FROM ('#{partition[:from]}') TO ('#{partition[:to]}')
      SQL
      @_partitions[table] = nil
    rescue DuplicatePartition
      @_partitions[table] = nil
    end

    def drop_partition(key, table = table_name, **options)
      connection.exec_query("DROP TABLE IF EXISTS #{partition_for(key, table, **options)[:name]}")
      @_partitions[table] = nil
    end

    def partitions(table = table_name)
      (@_partitions ||= {})[table] ||= begin
        connection.select_values(<<-SQL.strip_sql)
          SELECT inhrelid::regclass FROM pg_catalog.pg_inherits WHERE inhparent = '#{table}'::regclass ORDER BY 1
        SQL
      end
    end

    def partitions_buckets(table = table_name)
      m_access(:partitions_buckets, table) do
        partitions(table).map do |name|
          if (date = name[/\d{4}_\d{2}_\d{2}$/])
            Time.find_zone('UTC').parse(date.dasherize).utc
          else
            name[/\d{10}$/].to_i
          end
        end
      end
    end

    # TODO variable size
    def partition_for(key, table = table_name, size:)
      case key
      when Integer
        bucket = key / size
        from = bucket.to_s.rjust(10, '0')
        to = (bucket + size).to_s.rjust(10, '0')
      when Time, Date, DateTime
        raise UnsupportedPartitionBucket, "size: [#{size}]" unless size.in? TIME_PARTITION_BUCKETS
        date = key.send("beginning_of_#{size}")
        from = date.strftime('%Y_%m_%d')
        to = (date + 1.send(size)).strftime('%Y_%m_%d')
      else
        raise UnsupportedPartitionBucket, "key: [#{key}]"
      end
      { name: "#{table}_#{to}", from: from, to: to }
    end
  end
end
