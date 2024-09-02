module Monit
  module Linux
    class Cpu < Base
      attribute :boot_time, :datetime
      attribute :pids, :integer
      attribute :usage, :float
      attribute :steal, :float
      attribute :load_avg, :float

      def self.list
        load_avg = case
          when Setting[:monit_interval] < 5.minutes  then host.cpu_load[0]
          when Setting[:monit_interval] < 15.minutes then host.cpu_load[1]
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
          load_avg: load_avg.ceil(3),
        }]
      end

      def self.snapshot
        m_access(__method__) do
          keys = [:boot_time, :cpu_load, :cpu_pids, :cpu_work, :cpu_idle, :cpu_steal]
          values = Host.snapshot&.slice(*keys)
          values || keys.drop(2).map{ |k| [k, 0] }.to_h.merge(boot_time: Time.at(0), cpu_load: [0, 0, 0])
        end
      end

      def count
        self.class.host.cpu_count
      end

      def load_avg_issue?
        [load_avg].concat(self.class.snapshot[:cpu_load]).all?{ |value| value >= Setting[:monit_cpu_load_avg] }
      end

      def load_avg_warning?
        [load_avg].concat(self.class.snapshot[:cpu_load]).all?{ |value| value >= 0.7 }
      end

      def usage_issue?
        interval_ok? :usage, Setting[:monit_cpu_usage]
      end

      def usage_warning?
        interval_ok? :usage, 75.0
      end

      def steal_warning?
        interval_ok? :steal, 10.0
      end

      private

      def interval_ok?(attribute, threshold)
        last_records = LogLines::Host.last_records.limit(20.minutes / Setting[:monit_interval]).pluck(attribute)
        last_records.any? && (last_records << public_send(attribute)).all?{ |value| value >= threshold }
      end
    end
  end
end
