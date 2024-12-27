# frozen_string_literal: true

module MixSetting::Type
  extend ActiveSupport::Concern

  class_methods do
    private

    def cast(value, type)
      type = type.to_s
      case type
      when 'emails'
        value&.split(/[\s\t,;]/)&.reject(&:blank?)
      when 'csv'
        value.is_a?(String) ? CSV.parse_line(value, converters: [:numeric], strip: true) : value
      when /s$/
        type = type.chop
        (value || '').split(',').map!{ |element| cast(element.strip, type) }
      else
        case type&.to_sym
        when :array
          Array.wrap(value)
        when :json
          case value
          when Array then value
          when Hash  then value.to_hwka
          else ActiveSupport::JSON.decode(value).to_hwka
          end
        when :boolean
          value.to_b
        when :integer
          value.to_i
        when :decimal
          BigDecimal(value)
        when :datetime, :time
          Time.parse_utc(value)
        when :interval
          ActiveSupport::Duration.build(ChronicDuration.parse(value || '', keep_zero: true))
        when :pathname
          Pathname.new(value)
        else
          value
        end
      end
    end
  end
end
