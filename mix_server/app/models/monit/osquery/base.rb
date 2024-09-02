module Monit
  module Osquery
    class Base < Monit::Base
      def self.osquery
        m_access(__method__) do
          result = {}
          path = if Rails.env.local?
            MixServer::Engine.root.join('test/fixtures/files/log/osquery/osqueryd.results.log')
          else
            Pathname.new(MixServer::Log.config.osquery_log_path)
          end
          File.foreach(path, chomp: true) do |line|
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
