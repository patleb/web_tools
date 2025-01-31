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
          path = case Rails.env.to_sym
            when :test
              MixServer::Engine.root.join('test/fixtures/files/log/osquery/osqueryd.results.log')
            when :development
              i = $osquery_log_i.to_i? ? ".#{$osquery_log_i.to_i}" : ''
              Rails.root.join("config/sunzistrano/files/var/log/osquery/osqueryd.results.log#{i}")
            else
              Pathname.new(MixServer::Logs.config.osquery_log_path)
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
