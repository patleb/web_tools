module MixSetting::Type
  extend ActiveSupport::Concern

  CSV_OR_EMAILS = %w(csv emails)

  class_methods do
    def cast(value, type)
      type = type.to_s
      if type.in? CSV_OR_EMAILS
        value&.split(/[\s\t,;]/)&.reject(&:blank?)
      elsif type.end_with? 's'
        type = type.chop
        (value || '').split(',').map!{ |element| cast(element.strip, type) }
      else
        case type&.to_sym
        when :array
          Array.wrap(value)
        when :json
          case value
          when Array then value
          when Hash  then value.with_indifferent_access
          else ActiveSupport::JSON.decode(value).with_indifferent_access
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
