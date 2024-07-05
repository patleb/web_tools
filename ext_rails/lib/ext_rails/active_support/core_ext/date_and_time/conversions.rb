module DateAndTime
  module Conversions
    extend ActiveSupport::Concern

    class_methods do
      def from_f(...)
        Time.at(...)
      end
    end

    # NOTE $(date +%FT%T%z) --> YYYY-MM-DDTHH:MM:SS+ZZZZ
    # TODO `$(date +%s%N)`
    def to_nanoseconds
      to_i * (10 ** 9) + nsec
    end

    def rotations(days: nil, weeks: nil, months: nil, format: true)
      days ||= 5; days = 5 if days < 5; days = 6 if days > 6
      weeks ||= 3; weeks = 1 if weeks < 1; weeks = 3 if weeks > 3
      months ||= 2; months = 0 if months < 0
      current_day = beginning_of_day
      current_week = beginning_of_week
      all = current_day == current_week ? [] : (1..days - 1).each_with_object([current_week + 1.day]) do |i, memo|
        next if (day = memo.first + i.day) > current_day
        memo << day
      end.reverse
      week_day, *weeks = (1..weeks - 1).each_with_object([current_week]) do |i, memo|
        day = memo.first - i.week
        memo << day
      end
      all += [week_day] + (1..days - all.size).each_with_object([]) do |i, memo|
        day = all.empty? ? current_week - (6 - days).days - i.days : all.last - (7 - days).days - i.days
        memo << day
      end
      all += weeks
      if months > 0
        all += (1..months - 1).each_with_object([current_week - 3.weeks]) do |i, memo|
          day = memo.first - (i * 4).weeks
          memo << day
        end
      end
      format ? all.map{ |day| day.to_date.to_s(&:db).tr('-', '_') } : all
    end
  end
end
