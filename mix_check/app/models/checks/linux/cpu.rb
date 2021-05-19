module Checks
  module Linux
    class Cpu < Base
      attribute :boot_time, :datetime
      attribute :pids, :integer
      attribute :usage, :float
      attribute :steal, :float
      attribute :load_avg, :float

      def self.list
        load_avg = case
          when Setting[:check_host_interval] < 5.minutes  then host.cpu_load[0]
          when Setting[:check_host_interval] < 15.minutes then host.cpu_load[1]
          else host.cpu_load[2]
          end
        boot_time = host.boot_time if host.boot_time > snapshot[:boot_time]
        work = counter_value(host.cpu_work.to_i, snapshot[:cpu_work].to_i)
        idle = counter_value(host.cpu_idle.to_i, snapshot[:cpu_idle].to_i)
        steal = counter_value(host.cpu_steal.to_i, snapshot[:cpu_steal].to_i)
        [{
          id: 'cpu', boot_time: boot_time,
          pids: counter_value(host.cpu_pids, snapshot[:cpu_pids]),
          usage: usage(work, work + idle + steal),
          steal: usage(steal, work + idle + steal),
          load_avg: load_avg,
        }]
      end

      def self.snapshot
        m_access(:snapshot) do
          keys = [:boot_time, :cpu_load, :cpu_pids, :cpu_work, :cpu_idle, :cpu_steal]
          values = Host.snapshot&.slice(*keys)
          values || keys.drop(2).map{ |k| [k, 0] }.to_h.merge(boot_time: Time.at(0), cpu_load: [0, 0 , 0])
        end
      end

      def count
        self.class.host.cpu_count
      end

      def load_avg_issue?
        load_avg >= 1.0 && self.class.snapshot[:cpu_load].all?{ |value| value >= 1.0 }
      end

      def load_avg_warning?
        load_avg >= 0.7 && self.class.snapshot[:cpu_load].all?{ |value| value >= 0.7 }
      end

      def steal_warning?
        last_records = LogLines::Host.last_records.limit(20.minutes / Setting[:check_host_interval]).pluck(:steal)
        last_records.any? && (last_records << steal).all?(&:>=.with(10.0))
      end
    end
  end
end
