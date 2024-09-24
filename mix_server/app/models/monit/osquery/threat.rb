module Monit
  module Osquery
    class Threat < Base
      attribute :name
      attribute :time, :datetime
      attribute :end, :boolean

      def self.list
        (osquery.except(*LogLines::Osquery.monitors) || {}).flat_map do |name, threats|
          threats.select_map do |state, rows|
            rows.map do |row|
              time = row[:time]
              { id: [name, time].join(':'), name: name, time: Time.at(time).utc, end: state == :old }
            end
          end
        end
      end
    end
  end
end
