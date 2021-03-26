module MixLog
  class Cleanup < ActiveTask::Base
    class IntervalMismatch < ::StandardError; end

    def cleanup
      past_dates, current_dates = LogLine.partitions_dates.partition{ |date| date < dates.first }
      raise IntervalMismatch if (current_dates - dates).any?

      past_dates.each do |date|
        LogLine.drop_partition(date)
      end
    end

    private

    def dates
      @dates ||= begin
        interval = MixLog.config.partition_interval_type
        started_at = MixLog.config.partition_oldest.ago.utc.send("beginning_of_#{interval}")
        continue_at = Time.current.utc.send("beginning_of_#{interval}") + MixLog.config.partition_interval
        (started_at.to_i..continue_at.to_i).step(MixLog.config.partition_interval).map{ |s| Time.at(s).utc }
      end
    end
  end
end
