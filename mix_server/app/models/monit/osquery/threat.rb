module Monit
  module Osquery
    class Threat < Base
      attribute :name
      attribute :time, :datetime
      attribute :old, :boolean

      def self.list
        (osquery.except(*LogLines::Osquery.monitors) || {}).flat_map do |name, threats|
          threats.flat_map do |threat|
            threat.except(:time).flat_map do |state, rows|
              rows.map do |row|
                time = row[:time]
                { id: [name, time].join(':'), name: name, time: Time.at(time).utc, old: state == :old }
              end
            end
          end
        end
      end
    end
  end
end
