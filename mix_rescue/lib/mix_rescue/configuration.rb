module MixRescue
  has_config do
    attr_writer :skip_notice
    attr_writer :throttler_max_duration

    def skip_notice
      return @skip_notice if defined? @skip_notice
      @skip_notice = Rails.env.development?
    end

    def throttler_max_duration
      if @throttler_max_duration.is_a? Proc
        @throttler_max_duration.call
      else
        @throttler_max_duration ||= 4.hours
      end
    end
  end
end
