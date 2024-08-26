module MixServer
  module Rescue
    has_config do
      attr_writer :render_500
      attr_writer :notice_interval
      attr_writer :skip_notice
      attr_writer :throttler_max_duration

      def render_500
        return @render_500 if defined? @render_500
        @render_500 = !Rails.env.development?
      end
      alias_method :render_500?, :render_500

      def notice_interval
        @notice_interval ||= 24.hours
      end

      def skip_notice
        return @skip_notice if defined? @skip_notice
        @skip_notice = Rails.env.development?
      end

      def throttler_max_duration
        if @throttler_max_duration.is_a? Proc
          @throttler_max_duration.call
        else
          @throttler_max_duration ||= Float::INFINITY.hours
        end
      end
    end
  end
end
