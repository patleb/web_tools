module Checks
  module Osquery
    class Threat < Base
      attribute :name
      attribute :time, :datetime

      def self.list
        (osquery.except(*LogLines::Osquery.monitors) || {}).select_map do |name, rows|
          next if rows[:new].empty?
          time = rows[:time]
          { id: [name, time].join(':'), name: name, time: Time.at(time).utc }
        end
      end
    end
  end
end
