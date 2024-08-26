# frozen_string_literal: true

module Throttler
  PREFIX = 'throttler'

  def self.limit?(...)
    increment(...)[:limit]
  end

  def self.increment(key:, value: nil, to: 1, within: MixServer::Rescue.config.throttler_max_duration)
    new_value = normalize(value)
    new_time = Time.current
    throttled = false
    old_value = nil
    old_count = nil

    record = Global.write_record([PREFIX, key].flatten) do |record|
      if record.nil?
        { value: new_value, time: new_time.iso8601, count: 1 }
      else
        old_value, old_time, old_count = record.data.values_at(:value, :time, :count)

        if new_value != old_value
          next { value: new_value, time: new_time.iso8601, count: 1 }
        end

        old_time = Time.parse_utc(old_time)
        if (new_time - old_time).seconds >= within
          next { value: old_value, time: new_time.iso8601, count: 1 }
        end

        throttled = (old_count >= to)
        { value: old_value, time: old_time.iso8601, count: old_count + 1 }
      end
    end

    if record.new?
      { limit: false }
    else
      { limit: throttled, was: [old_value, old_count] }
    end
  end

  def self.clear(prefix = nil)
    Global.delete_matched [PREFIX, prefix]
  end

  def self.normalize(value)
    case value
    when Symbol
      value.to_s
    when String, Array, nil
      value
    when Hash
      value.deep_stringify_keys
    else
      value.class.to_s
    end
  end
  private_class_method :normalize
end
