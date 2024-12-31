module DateAndTime
  module Conversions
    extend ActiveSupport::Concern

    class_methods do
      def from_f(...)
        Time.at(...)
      end
    end

    def date_tag
      strftime('%Y_%m_%d')
    end

    def to_nanoseconds
      to_i * (10 ** 9) + nsec
    end

    def rotations(days: nil, weeks: nil, months: nil, format: true)
      days ||= 5; weeks ||= 3; months ||= 2
      days = rotations_for(days, :day)
      weeks = rotations_for(weeks, :week)
      months = rotations_for(months, :month)
      all = SortedSet.new(days + weeks + months).to_a.reverse
      format ? all.map(&:date_tag) : all
    end

    private

    def rotations_for(max, unit)
      max = 0 if max < 0
      current = public_send("beginning_of_#{unit}")
      if unit == :day
        return [current] if max <= 1
      else
        return [] if max == 0
      end
      (0...max - 1).each_with_object([current]) do |_, memo|
        memo << memo.last - 1.public_send(unit)
      end
    end
  end
end
