module LogLines::WithPartition
  extend ActiveSupport::Concern

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

  class_methods do
    def insert_all!(attributes, **)
      with_partition(attributes){ super }
    end

    def insert_all(attributes, **)
      with_partition(attributes){ super }
    end

    def upsert_all(attributes, **)
      with_partition(attributes){ super }
    end

    def with_partition(attributes)
      yield
    rescue MissingPartition
      attributes.each{ |row| create_partition(row[:created_at]) }
      retry
    end

    def create_partition(date)
      partition = partition_for(date)
      return if partitions.include? partition[:name]
      connection.exec_query("CREATE TABLE #{partition[:name]} PARTITION OF #{table_name} FOR VALUES FROM ('#{partition[:from]}') TO ('#{partition[:to]}')")
      m_clear(:partitions)
    rescue DuplicatePartition
      m_clear(:partitions)
    end

    def drop_partition(date)
      connection.exec_query("DROP TABLE IF EXISTS #{partition_for(date)[:name]}")
      m_clear(:partitions)
    end

    def partitions_dates
      partitions.map{ |name| Time.find_zone('UTC').parse(name[/\d{4}_\d{2}_\d{2}$/].dasherize).utc }
    end

    def partitions
      m_access(:partitions) do
        connection.select_values("SELECT inhrelid::regclass FROM pg_catalog.pg_inherits WHERE inhparent = '#{table_name}'::regclass ORDER BY 1")
      end
    end

    # this is the variable part, otherwise it should be the same logic for other classes
    def partition_for(date)
      date = date.send("beginning_of_#{MixLog.config.partition_interval_type}")
      from_date = date.strftime('%Y_%m_%d')
      next_date = (date + MixLog.config.partition_interval).strftime('%Y_%m_%d')
      partition = "#{table_name}_#{from_date}"
      { name: partition, from: from_date, to: next_date }
    end
  end
end
