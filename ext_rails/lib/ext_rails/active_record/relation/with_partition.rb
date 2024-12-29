module ActiveRecord::Relation::WithPartition
  extend ActiveSupport::Concern

  prepended do
    delegate :partition_size, :with_partition, to: :klass
  end

  def insert_all!(rows, **)
    partition_size ? with_partition(rows){ super } : super
  end

  def insert_all(rows, **)
    partition_size ? with_partition(rows){ super } : super
  end

  def upsert_all(rows, **)
    partition_size ? with_partition(rows){ super } : super
  end
end
