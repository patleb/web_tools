module ActiveSupport
  Duration.class_eval do
    UNITS = self::PARTS.map.with_index.to_h

    alias_method :to_s_without_format, :to_s
    def to_s(unit = nil, compact: false)
      return to_s_without_format if unit.nil?
      parts = @parts.slice(*self.class::PARTS[UNITS[unit] + 1..-1]).map{ |unit, val| i18n(unit, val, compact) }
      value = public_send("in_#{unit}").floor
      parts = [i18n(unit, value, compact)].concat(parts) unless value == 0
      parts.join(', ')
    end

    private

    def i18n(unit, count, compact)
      I18n.t(unit, count: count, scope: compact ? 'datetime.dotiw_compact' : 'datetime.dotiw')
    end
  end
end
