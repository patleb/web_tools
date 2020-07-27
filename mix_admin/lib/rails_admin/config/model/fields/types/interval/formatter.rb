module RailsAdmin::Config::Model::Fields::Interval::Formatter
  extend ActiveSupport::Concern

  included do
    register_instance_option :pretty_format, memoize: true do
      :long
    end

    def format_interval(value = self.value)
      case pretty_format
      when :long
        value&.to_days
      when :short
        value&.to_hours
      when :ceil
        value&.to_days(ceil: true)
      when :floor
        value&.to_hours(ceil: true)
      else
        value.to_s
      end
    end
  end
end
