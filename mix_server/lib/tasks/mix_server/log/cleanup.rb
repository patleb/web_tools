module MixServer::Log
  class Cleanup < ActiveTask::Base
    def cleanup
      first_date = MixServer::Log.config.partitions_total_size.ago.utc.public_send("beginning_of_#{LogLine.partition_size}")
      past_dates = LogLine.partitions_buckets.select{ |date| date < first_date }
      LogLine.drop_all_partitions! past_dates
    end
  end
end
