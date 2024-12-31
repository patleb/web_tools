module GlobalCache
  extend ActiveSupport::Concern

  class_methods do
    def exist?(name, **)
      read_record(name).present?
    end

    def fetch!(name, **, &)
      fetch(name, **, expires: false, &)
    end

    def fetch(...)
      fetch_record(...)&.data
    end

    def fetch_multi!(*, **, &)
      fetch_multi(*, **, expires: false, &)
    end

    def fetch_multi(*names, **, &)
      raise ArgumentError, "Missing block: Calling `Global#fetch_multi` requires a block." unless block_given?

      results = read_multi(*names, **)
      (names.map{ |element| normalize_key(element, server: false) } - results.keys).each do |name|
        record = fetch_record(name, **, &)
        results[name] = record.data
      end
      results
    end

    def [](name)
      read(name)
    end

    def read(name, **)
      read_record(name)&.data
    end

    def read_multi(matcher = nil, *names, **)
      return {}.to_hwia if matcher.nil?
      names = matcher.is_a?(Regexp) ? matcher : [matcher].concat(names)
      read_records(names).transform_values!(&:data)
    end

    def []=(name, value)
      write! name, value
    end

    def write!(*, **, &)
      write(*, **, expires: false, &)
    end

    def write(name, value, **, &)
      write_record(name, value, **, &)
      value
    end

    def write_multi!(hash, **, &)
      write_multi(hash, **, expires: false, &)
    end

    def write_multi(hash, **, &)
      hash.each_with_object({}.to_hwia) do |(name, value), result|
        record = write_record(name, value, **, &)
        result[key_name(record)] = value
      end
    end

    def increment!(*, **)
      increment(*, **, expires: false)
    end

    def increment(name, amount = 1, **)
      update_integer(name, amount, **)
    end

    def decrement!(*, **)
      decrement(*, **, expires: false)
    end

    def decrement(name, amount = 1, **)
      update_integer(name, -amount, **)
    end

    def delete(name, **)
      delete_record(name)
    end

    def delete_multi(names, **)
      delete_records(*names)
    end

    def delete_matched(matcher, **)
      delete_records(matcher)
    end

    def cleanup(**)
      expired.delete_all
    end

    def clear(**)
      expirable.delete_all
    end

    def clear!
      with_table_lock do
        connection.exec_query("TRUNCATE TABLE #{quoted_table_name}")
      end
    end
  end
end
