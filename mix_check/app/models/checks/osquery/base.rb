module Checks
  module Osquery
    class Base < Checks::Base
      def self.osquery
        @@osquery ||= begin
          result = {}
          path = if Rails.env.dev_or_test?
            MixLog::Engine.root.join('test/fixtures/files/log/osquery/osqueryd.results.log')
          else
            Pahtname.new(MixLog.config.osquery_log_path)
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
