module RailsAdmin::Config::Model::Fields::Interval::Formatter
  extend ActiveSupport::Concern

  included do
    register_instance_option :pretty_format, memoize: true do
      :long
    end

    def format_interval(value = self.value)
      case pretty_format
      when :long
        value&.pretty_days
      when :short
        value&.pretty_hours
      when :ceil
        value&.pretty_days(ceil: true)
      when :floor
        value&.pretty_hours(ceil: true)
      else
        value.to_s
      end
    end
  end
end
