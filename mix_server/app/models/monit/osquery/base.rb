module Monit
  module Osquery
    class Base < Monit::Base
      def self.clear
        Monit::Osquery::Base.descendants.each(&:m_clear)
        reset
      end

      def self.osquery(i = nil)
        @@osquery ||= if i == :all
          result = read_file
          i = 1
          until (partial = read_file i).empty?
            result.merge!(partial) do |key, old_value, new_value|
              old_value.concat new_value
            end
            i += 1
          end
          result
        elsif i
          read_file i
        else
          read_file
        end
      end

      def self.read_file(i = nil)
        result = {}
        if Rails.env.test?
          path = MixServer::Engine.root.join('test/fixtures/files/log/osquery/osqueryd.results.log')
        else
          suffix = ".#{i}" if i && i > 0
          path = if Rails.env.development?
            Rails.root.join("tmp/log/osquery/osqueryd.results.log#{suffix}.gz")
          else
            Pathname.new("#{MixServer::Logs.config.osquery_log_path}#{suffix}.gz")
          end
          unless path.exist?
            path = path.sub_ext('')
          end
        end
        if path.exist?
          File.each_line(path, chomp: true) do |line|
            json = JSON.parse(line)
            name, time, diff = json.values_at('name', 'unixTime', 'diffResults')
            next unless LogLines::Osquery.names.include? name
            (result[name] ||= []) << { time: time, old: diff['removed'], new: diff['added'] }
          end
        end
        result
      rescue Errno::ENOENT
        result
      end
      private_class_method :read_file
    end
  end
end
