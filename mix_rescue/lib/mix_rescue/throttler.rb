module Throttler
  PREFIX = 'throttler'.freeze

  def self.status(key:, value: nil, duration: nil)
    new_value = normalize(value)
    new_time = Time.current
    throttled = false
    old_value = nil
    old_count = nil

    record = Global.write_record([PREFIX, key].flatten, expires: false) do |record|
      if record.nil?
        { value: new_value, time: new_time.iso8601, count: 1 }
      else
        old_value, old_time, old_count = record.data.values_at(:value, :time, :count)

        if new_value != old_value
          next { value: new_value, time: new_time.iso8601, count: 1 }
        end

        old_time = Time.zone.parse(old_time)
        if (new_time - old_time).seconds >= (duration || MixRescue.config.throttler_max_duration)
          next { value: old_value, time: new_time.iso8601, count: 1 }
        end

        if block_given? && !yield(old_time, old_count)
          next { value: old_value, time: new_time.iso8601, count: 1 }
        end

        throttled = true
        { value: old_value, time: old_time.iso8601, count: old_count + 1 }
      end
    end

    if record.new?
      { throttled: false }
    else
      { throttled: throttled, previous: old_value, count: old_count }
    end
  end

  def self.clear(prefix = nil)
    Global.delete_matched [PREFIX, prefix]
  end

  private_class_method

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
end
