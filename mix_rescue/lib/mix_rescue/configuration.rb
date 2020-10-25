module MixRescue
  has_config do
    attr_writer :rescue_500
    attr_writer :skip_notice
    attr_writer :throttler_max_duration
    attr_writer :excluded_errors
    attr_writer :available_types

    def rescue_500
      return @rescue_500 if defined? @rescue_500
      @rescue_500 = !Rails.env.dev_or_test?
    end

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

    def excluded_errors
      @excluded_errors ||= Set.new
    end

    def available_types
      @available_types ||= {
        'Rescue' => 0,
        'Rescues::Javascript' => 10,
      }
    end
  end
end
