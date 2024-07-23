module MixLog
  class Cleanup < ActiveTask::Base
    class IntervalMismatch < ::StandardError; end

    def cleanup
      past_dates, current_dates = LogLine.partitions_buckets.partition{ |date| date < dates.first }
      raise IntervalMismatch if (current_dates - dates).any?
      LogLine.drop_all_partitions! past_dates
    end

    private

    def dates
      @dates ||= begin
        size = LogLine.partition_size
        interval = 1.send(size)
        started_at = MixLog.config.partitions_total_size.ago.utc.send("beginning_of_#{size}")
        continue_at = Time.current.utc.send("beginning_of_#{size}") + interval
        (started_at.to_i..continue_at.to_i).step(interval).map{ |s| Time.at(s).utc }
      end
    end
  end
end
