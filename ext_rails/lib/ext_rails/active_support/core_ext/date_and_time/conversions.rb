module DateAndTime
  module Conversions
    # NOTE $(date +%FT%T%z) --> YYYY-MM-DDTHH:MM:SS+ZZZZ
    # TODO `$(date +%s%N)`
    def to_nanoseconds
      to_i * (10 ** 9) + nsec
    end
  end
end
