module MrThrottler
  has_config do
    attr_writer :max_duration

    def max_duration
      if @max_duration.is_a? Proc
        @max_duration.call
      else
        @max_duration ||= 4.hours
      end
    end
  end
end
