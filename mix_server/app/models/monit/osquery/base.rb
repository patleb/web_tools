module Monit
  module Osquery
    class Base < Monit::Base
      def self.clear
        Monit::Osquery::Base.descendants.each(&:m_clear)
        reset
      end

      def self.osquery
        m_access(__method__, $osquery_log_i) do
          result = {}
          path = if Rails.env.test?
            MixServer::Engine.root.join('test/fixtures/files/log/osquery/osqueryd.results.log')
          else
            if (i = $osquery_log_i.to_i) > 0
              suffix = ".#{i}"
            end
            if Rails.env.development?
              Rails.root.join("tmp/log/osquery/osqueryd.results.log#{suffix}.gz")
            else
              Pathname.new("#{MixServer::Logs.config.osquery_log_path}#{suffix}.gz")
            end
            unless path.exist?
              path = path.sub_ext('')
            end
          end
          File.each_line(path, chomp: true) do |line|
            json = JSON.parse(line)
            name, time, diff = json.values_at('name', 'unixTime', 'diffResults')
            next unless LogLines::Osquery.names.include? name
            (result[name] ||= []) << { time: time, old: diff['removed'], new: diff['added'] }
          end
          result
        rescue Errno::ENOENT
          result
        end
      end
    end
  end
end
