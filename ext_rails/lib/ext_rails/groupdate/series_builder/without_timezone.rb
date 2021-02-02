module Groupdate::SeriesBuilder::WithoutTimezone
  private

  def key_format
    @key_format ||= begin
      # locale = options[:locale] || I18n.locale
      use_dates = options.key?(:dates) ? options[:dates] : Groupdate.dates

      if options[:format]
        super
      elsif [:day, :week, :month, :quarter, :year].include?(period) && use_dates
        lambda { |k| k.utc.to_date } # I18n.localize(k.utc, format: '%Y-%m-%d', locale: locale) }
      else
        lambda { |k| k.utc }
      end
    end
  end
end

Groupdate::SeriesBuilder.prepend Groupdate::SeriesBuilder::WithoutTimezone
